# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::Requirement do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    subject { build(:requirement) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:test_reports).through(:requirement_issue) }
    it { is_expected.to have_many(:recent_test_reports).through(:requirement_issue).order('requirements_management_test_reports.created_at DESC') }

    it_behaves_like 'a model with a requirement issue association'
  end

  describe 'delegate' do
    subject { build(:requirement) }

    delegated_attributes = %i[
      author author_id title title_html description
      description_html cached_markdown_version
    ]

    delegated_attributes.each do |attr_name|
      it { is_expected.to delegate_method(attr_name).to(:requirement_issue).allow_nil }
    end

    context 'with nil attributes' do
      let_it_be(:requirement) { create(:requirement, project: project, author: user, description: 'Test', state: 'archived') }

      (delegated_attributes - [:title]).each do |attr_name|
        it "returns delegated #{attr_name} value" do
          requirement.update_attribute(attr_name, nil)

          expect(requirement.send(attr_name)).not_to be_nil
          expect(requirement.send(attr_name)).to eq(requirement.requirement_issue.send(attr_name))
        end
      end
    end
  end

  describe 'validations' do
    subject { build(:requirement) }

    it { is_expected.to validate_uniqueness_of(:issue_id) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:requirement_issue) }

    it 'is limited to a unique requirement_issue' do
      requirement_issue = create(:requirement_issue)
      requirement = create(:requirement, requirement_issue: requirement_issue)
      requirement.save!

      subject.requirement_issue = requirement_issue

      expect(subject).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.counts_by_state' do
      let_it_be(:opened) { create(:requirement, project: project, state: :opened) }
      let_it_be(:archived) { create(:requirement, project: project, state: :archived) }

      subject { described_class.counts_by_state }

      it { is_expected.to contain_exactly(['archived', 1], ['opened', 1]) }
    end

    describe '.with_author' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:my_requirement) { create(:requirement, project: project, author: user) }
      let_it_be(:other_requirement) { create(:requirement, project: project, author: other_user) }

      context 'with one author' do
        subject { described_class.with_author(user) }

        it { is_expected.to contain_exactly(my_requirement) }
      end

      context 'with multiple authors' do
        subject { described_class.with_author([user, other_user]) }

        it { is_expected.to contain_exactly(my_requirement, other_requirement) }
      end
    end

    describe '.search' do
      let_it_be(:requirement_one) { create(:requirement, project: project, title: "it needs to do the thing") }
      let_it_be(:requirement_two) { create(:requirement, project: project, title: "it needs to not break") }

      subject { described_class.search(query) }

      context 'with a query that covers both' do
        let(:query) { 'it needs to' }

        it { is_expected.to contain_exactly(requirement_one, requirement_two) }
      end

      context 'with a query that covers neither' do
        let(:query) { 'break often' }

        it { is_expected.to be_empty }
      end

      context 'with a query that covers one' do
        let(:query) { 'do the thing' }

        it { is_expected.to contain_exactly(requirement_one) }
      end
    end

    describe '.with_last_test_report_state' do
      let_it_be(:requirement1) { create(:requirement) }
      let_it_be(:requirement2) { create(:requirement) }
      let_it_be(:requirement3) { create(:requirement) }

      before do
        create(:test_report, requirement_issue: requirement1.requirement_issue, state: :passed)
        create(:test_report, requirement_issue: requirement1.requirement_issue, state: :failed)
        create(:test_report, requirement_issue: requirement2.requirement_issue, state: :failed)
        create(:test_report, requirement_issue: requirement2.requirement_issue, state: :passed)
        create(:test_report, requirement_issue: requirement3.requirement_issue, state: :passed)
      end

      subject { described_class.with_last_test_report_state(state) }

      context 'for passed state' do
        let(:state) { 'passed' }

        it { is_expected.to contain_exactly(requirement2, requirement3) }
      end

      context 'for failed state' do
        let(:state) { 'failed' }

        it { is_expected.to contain_exactly(requirement1) }
      end
    end

    describe '.for_state' do
      let_it_be(:requirement1) { create(:requirement, state: :opened) }
      let_it_be(:requirement2) { create(:requirement, state: :archived) }

      context 'for opened state' do
        subject { described_class.for_state(:opened) }

        it { is_expected.to contain_exactly(requirement1) }
      end

      context 'for archived state' do
        subject { described_class.for_state(:archived) }

        it { is_expected.to contain_exactly(requirement2) }
      end
    end

    describe 'ordering' do
      let_it_be(:requirement1) { create(:requirement, created_at: 6.days.ago, updated_at: 4.days.ago) }
      let_it_be(:requirement2) { create(:requirement, created_at: 5.days.ago, updated_at: 3.days.ago) }
      let_it_be(:requirement3) { create(:requirement, created_at: 4.days.ago, updated_at: 2.days.ago) }

      describe '.order_created_desc' do
        subject { described_class.order_created_desc }

        it { is_expected.to eq([requirement3, requirement2, requirement1]) }
      end

      describe '.order_created_asc' do
        subject { described_class.order_created_asc }

        it { is_expected.to eq([requirement1, requirement2, requirement3]) }
      end

      describe '.order_updated_desc' do
        subject { described_class.order_updated_desc }

        it { is_expected.to eq([requirement3, requirement2, requirement1]) }
      end

      describe '.order_updated_asc' do
        subject { described_class.order_updated_asc }

        it { is_expected.to eq([requirement1, requirement2, requirement3]) }
      end
    end
  end

  describe '.without_test_reports' do
    let_it_be(:requirement1) { create(:requirement) }
    let_it_be(:requirement2) { create(:requirement) }

    before do
      create(:test_report, requirement_issue: requirement2.requirement_issue, state: :passed)
    end

    it 'returns requirements without test reports' do
      expect(described_class.without_test_reports).to contain_exactly(requirement1)
    end
  end

  describe '#last_test_report_state' do
    let_it_be(:requirement) { create(:requirement) }

    context 'when latest test report is passing' do
      it 'returns passing' do
        create(:test_report, requirement_issue: requirement.requirement_issue, state: :passed, build: nil)

        expect(requirement.last_test_report_state).to eq('passed')
      end
    end

    context 'when latest test report is failing' do
      it 'returns failing' do
        create(:test_report, requirement_issue: requirement.requirement_issue, state: :failed, build: nil)

        expect(requirement.last_test_report_state).to eq('failed')
      end
    end

    context 'when there are no test reports' do
      it 'returns nil' do
        expect(requirement.last_test_report_state).to eq(nil)
      end
    end
  end

  describe '#status_manually_updated' do
    let_it_be(:requirement) { create(:requirement) }

    context 'when latest test report has a build' do
      it 'returns false' do
        create(:test_report, requirement_issue: requirement.requirement_issue, state: :passed)

        expect(requirement.last_test_report_manually_created?).to eq(false)
      end
    end

    context 'when latest test report does not have a build' do
      it 'returns true' do
        create(:test_report, requirement_issue: requirement.requirement_issue, state: :passed, build: nil)

        expect(requirement.last_test_report_manually_created?).to eq(true)
      end
    end
  end

  describe 'sync with requirement issues' do
    let_it_be_with_reload(:requirement) { create(:requirement) }
    let_it_be_with_reload(:requirement_issue) { create(:requirement_issue, requirement: requirement) }

    context 'when destroying a requirement' do
      it 'also destroys the associated requirement issue' do
        expect { requirement.destroy! }.to change { Issue.where(issue_type: 'requirement').count }.by(-1)
      end
    end

    context 'when destroying a requirement issue' do
      it 'also destroys the associated requirement' do
        expect { requirement_issue.destroy! }.to change { RequirementsManagement::Requirement.count }.by(-1)
      end
    end
  end

  describe '#state' do
    let_it_be_with_reload(:requirement) { create(:requirement, state: :archived) }

    context 'when linked requirement issue is not present' do
      before do
        requirement.requirement_issue = nil
      end

      it 'returns nil' do
        expect(requirement.state).to be_nil
      end
    end

    context 'when linked requirement issue is present' do
      it 'returns requirement issue stored state' do
        requirement.requirement_issue.state = 'opened'

        expect(requirement.state).to eq('opened')
      end

      it 'returns mapped value for state' do
        requirement.requirement_issue.state = 'closed'

        expect(requirement.state).to eq('archived')
      end
    end
  end
end
