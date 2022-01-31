# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteInvalidEpicIssues do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  let!(:users) { table(:users) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }
  let!(:epics) { table(:epics) }
  let!(:issues) { table(:issues) }
  let!(:epic_issues) { table(:epic_issues) }

  let!(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }

  let!(:root_group) do
    namespaces.create!(id: 1, name: 'root-group', path: 'root-group',
                       type: 'Group', traversal_ids: [1])
  end

  let!(:group) do
    namespaces.create!(id: 2, name: 'group', path: 'group', parent_id: root_group.id,
                       type: 'Group', traversal_ids: [1, 2])
  end

  let!(:sub_group) do
    namespaces.create!(id: 3, name: 'subgroup', path: 'subgroup', parent_id: group.id,
                       type: 'Group', traversal_ids: [1, 2, 3])
  end

  let!(:other_group) do
    namespaces.create!(id: 4, name: 'other group', path: 'other-group',
                       type: 'Group', traversal_ids: [4])
  end

  let!(:project_root) do
    projects.create!(namespace_id: root_group.id, project_namespace_id: root_group.id,
                     name: 'root group project', path: 'root-group-project')
  end

  let!(:project) do
    projects.create!(namespace_id: group.id, project_namespace_id: group.id,
                     name: 'group project', path: 'group-project')
  end

  let!(:project_sub) do
    projects.create!(namespace_id: sub_group.id, project_namespace_id: sub_group.id,
                     name: 'subgroup project', path: 'subgroup-project')
  end

  let!(:project_other) do
    projects.create!(namespace_id: other_group.id, project_namespace_id: other_group.id,
                     name: 'other group project', path: 'other-group-project')
  end

  describe '#perform' do
    let(:batch_table) { :epics }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 100 }
    let(:pause_ms) { 0 }
    let(:connection) { ApplicationRecord.connection }
    let!(:epic_before) do
      epics.create!(iid: 1, title: 'epic-before', title_html: 'epic before',
                    group_id: group.id, author_id: user.id)
    end

    let!(:epic) do
      epics.create!(iid: 2, title: 'group-epic', title_html: 'group-epic',
                    group_id: group.id, author_id: user.id)
    end

    let!(:epic_root) do
      epics.create!(iid: 3, title: 'root-group-epic', title_html: 'root-group-epic',
                    group_id: root_group.id, author_id: user.id)
    end

    let!(:epic_sub) do
      epics.create!(iid: 4, title: 'subgroup-epic', title_html: 'subgroup-epic',
                    group_id: sub_group.id, author_id: user.id)
    end

    let!(:epic_other) do
      epics.create!(iid: 5, title: 'other-group-epic', title_html: 'other-group-epic',
                    group_id: other_group.id, author_id: user.id)
    end

    let!(:epic_last) do
      epics.create!(iid: 6, title: 'epic_last', title_html: 'epic_last',
                    group_id: group.id, author_id: user.id)
    end

    let!(:issue) { issues.create!(iid: 1, project_id: project.id, title: 'issue 1', author_id: user.id) }
    let!(:issue2) { issues.create!(iid: 2, project_id: project.id, title: 'issue 2', author_id: user.id) }
    let!(:issue3) { issues.create!(iid: 3, project_id: project.id, title: 'issue 3', author_id: user.id) }
    let!(:issue4) { issues.create!(iid: 4, project_id: project.id, title: 'issue 4', author_id: user.id) }
    let!(:issue5) { issues.create!(iid: 5, project_id: project.id, title: 'issue 5', author_id: user.id) }
    let!(:issue_root) { issues.create!(iid: 6, project_id: project_root.id, title: 'issue_root', author_id: user.id) }
    let!(:issue_sub) { issues.create!(iid: 7, project_id: project_sub.id, title: 'issue_sub', author_id: user.id) }
    let!(:issue_sub2) { issues.create!(iid: 8, project_id: project_sub.id, title: 'issue_sub 2', author_id: user.id) }
    let!(:issue_sub3) { issues.create!(iid: 9, project_id: project_sub.id, title: 'issue_sub 3', author_id: user.id) }
    let!(:issue_other) { issues.create!(iid: 10, project_id: project_other.id, title: 'other', author_id: user.id) }
    let!(:issue_other_2) { issues.create!(iid: 11, project_id: project_other.id, title: 'other 2', author_id: user.id) }
    let!(:issue_other_3) { issues.create!(iid: 12, project_id: project_other.id, title: 'other 3', author_id: user.id) }
    let!(:issue_other_4) { issues.create!(iid: 13, project_id: project_other.id, title: 'other 4', author_id: user.id) }

    let!(:valid_and_invalid_epic_issues) do
      invalid_epic_issues = []
      valid_epic_issues   = []

      # group's issues linked to epic in group's ancestor
      valid_epic_issues << epic_issues.create!(issue_id: issue4.id, epic_id: epic_root.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_sub2.id, epic_id: epic.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_sub3.id, epic_id: epic_root.id)

      # issues and epics in the same group
      valid_epic_issues << epic_issues.create!(issue_id: issue.id, epic_id: epic.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue3.id, epic_id: epic_last.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_sub.id, epic_id: epic_sub.id)
      valid_epic_issues << epic_issues.create!(issue_id: issue_other_2.id, epic_id: epic_other.id)

      # invalid link that is not deleted because epic_before is not included in epics batch
      valid_epic_issues << epic_issues.create!(issue_id: issue_other.id, epic_id: epic_before.id)

      # group's issues linked to epic in group's descendant
      invalid_epic_issues << epic_issues.create!(issue_id: issue2.id, epic_id: epic_sub.id)
      invalid_epic_issues << epic_issues.create!(issue_id: issue_root.id, epic_id: epic_sub.id)

      # issues linked to epics in a different group hierarchy
      invalid_epic_issues << epic_issues.create!(issue_id: issue_other_4.id, epic_id: epic_root.id)
      invalid_epic_issues << epic_issues.create!(issue_id: issue_other_3.id, epic_id: epic_sub.id)
      invalid_epic_issues << epic_issues.create!(issue_id: issue5.id, epic_id: epic_other.id)

      { valid: valid_epic_issues, invalid: invalid_epic_issues }
    end

    let(:valid_epic_issues) { valid_and_invalid_epic_issues[:valid] }
    let(:invalid_epic_issues) { valid_and_invalid_epic_issues[:invalid] }

    let(:migration) do
      described_class.new(
        start_id: epic.id, end_id: epic_last.id, batch_table: batch_table, batch_column: batch_column,
        sub_batch_size: sub_batch_size, pause_ms: pause_ms, connection: connection
      )
    end

    subject { migration.perform }

    it 'removes invalid epic issues' do
      expect { subject }.to change { epic_issues.count }.from(13).to(8)

      expect(epic_issues.all).to match_array(valid_epic_issues)
    end

    it 'logs deleted records' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:info).once.with(message: 'Removing EpicIssue records',
                                                    migrator: 'DeleteInvalidEpicIssues',
                                                    data: invalid_epic_issues.map(&:attributes),
                                                    deleted_count: invalid_epic_issues.size)
      end

      subject
    end

    it 'prevents N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        subject
      end

      # recreate deleted records
      epic_issues.create!(issue_id: issue2.id, epic_id: epic_sub.id)
      epic_issues.create!(issue_id: issue_root.id, epic_id: epic_sub.id)
      epic_issues.create!(issue_id: issue_other_4.id, epic_id: epic_root.id)
      epic_issues.create!(issue_id: issue_other_3.id, epic_id: epic_sub.id)
      epic_issues.create!(issue_id: issue5.id, epic_id: epic_other.id)

      # create new records to delete
      issue6 = issues.create!(iid: 14, project_id: project.id, title: 'issue 6', author_id: user.id)
      issue7 = issues.create!(iid: 15, project_id: project.id, title: 'issue 7', author_id: user.id)
      epic_issues.create!(issue_id: issue6.id, epic_id: epic_other.id)
      epic_issues.create!(issue_id: issue7.id, epic_id: epic_other.id)

      expect { subject }.not_to exceed_all_query_limit(control)
    end
  end
end
