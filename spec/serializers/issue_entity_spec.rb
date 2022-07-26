# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEntity do
  include Gitlab::Routing.url_helpers

  let(:project)  { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  describe 'web_url' do
    context 'when issue is of type task' do
      let(:resource) { create(:issue, :task, project: project) }

      # This was already a path and not a url when the work items change was introduced
      it 'has a work item path' do
        expect(subject[:web_url]).to eq(project_work_items_path(project, resource.id))
      end
    end
  end

  describe 'type' do
    it 'has an issue type' do
      expect(subject[:type]).to eq('ISSUE')
    end
  end

  it 'has Issuable attributes' do
    expect(subject).to include(:id, :iid, :author_id, :description, :lock_version, :milestone_id,
                               :title, :updated_by_id, :created_at, :updated_at, :milestone, :labels)
  end

  it 'has time estimation attributes' do
    expect(subject).to include(:time_estimate, :total_time_spent, :human_time_estimate, :human_total_time_spent)
  end

  describe 'current_user' do
    it 'has the exprected permissions' do
      expect(subject[:current_user]).to include(:can_create_note, :can_update, :can_set_issue_metadata,
                                                :can_award_emoji)
    end
  end

  context 'when issue got moved' do
    let(:public_project) { create(:project, :public) }
    let(:member) { create(:user) }
    let(:non_member) { create(:user) }
    let(:issue) { create(:issue, project: public_project) }

    before do
      project.add_developer(member)
      public_project.add_developer(member)
      Issues::MoveService.new(project: public_project, current_user: member).execute(issue, project)
    end

    context 'when user cannot read target project' do
      it 'does not return moved_to_id' do
        request = double('request', current_user: non_member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to be_nil
      end
    end

    context 'when user can read target project' do
      it 'returns moved moved_to_id' do
        request = double('request', current_user: member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:moved_to_id]).to eq(issue.moved_to_id)
      end
    end
  end

  context 'when issue got duplicated' do
    let(:private_project) { create(:project, :private) }
    let(:member) { create(:user) }
    let(:issue) { create(:issue, project: project) }
    let(:new_issue) { create(:issue, project: private_project) }

    before do
      Issues::DuplicateService
        .new(project: project, current_user: member)
        .execute(issue, new_issue)
    end

    context 'when user cannot read new issue' do
      let(:non_member) { create(:user) }

      it 'does not return duplicated_to_id' do
        request = double('request', current_user: non_member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:duplicated_to_id]).to be_nil
      end
    end

    context 'when user can read target project' do
      before do
        project.add_developer(member)
        private_project.add_developer(member)
      end

      it 'returns duplicated duplicated_to_id' do
        request = double('request', current_user: member)

        response = described_class.new(issue, request: request).as_json

        expect(response[:duplicated_to_id]).to eq(issue.duplicated_to_id)
      end
    end
  end

  context 'when issuable in active or archived project' do
    before do
      project.add_developer(user)
    end

    context 'when project is active' do
      it 'returns archived false' do
        expect(subject[:is_project_archived]).to eq(false)
      end

      it 'returns nil for archived project doc' do
        response = described_class.new(resource, request: request).as_json

        expect(response[:archived_project_docs_path]).to be nil
      end
    end

    context 'when project is archived' do
      before do
        project.update!(archived: true)
      end

      it 'returns archived true' do
        expect(subject[:is_project_archived]).to eq(true)
      end

      it 'returns archived project doc' do
        expect(subject[:archived_project_docs_path]).to eq('/help/user/project/settings/index.md#archive-a-project')
      end
    end
  end
end
