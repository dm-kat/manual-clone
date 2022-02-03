# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEvents::CreateService do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:user_without_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_refind(:incident) { create(:incident, project: project) }

  let(:current_user) { user_with_permissions }
  let(:args) { { 'note': 'note', 'occurred_at': Time.current, 'action': 'new comment' } }
  let(:service) { described_class.new(incident, current_user, args) }

  before do
    stub_licensed_features(incident_timeline_events: true)
  end

  before_all do
    project.add_developer(user_with_permissions)
    project.add_reporter(user_without_permissions)
  end

  describe '#execute' do
    shared_examples 'error response' do |message|
      it 'has an informative message' do
        expect(execute).to be_error
        expect(execute.message).to eq(message)
      end
    end

    shared_examples 'success response' do
      it 'has timeline event' do
        expect(execute).to be_success

        result = execute.payload[:timeline_event]
        expect(result).to be_a(::IncidentManagement::TimelineEvent)
        expect(result.author).to eq(current_user)
        expect(result.incident).to eq(incident)
        expect(result.project).to eq(project)
        expect(result.note).to eq(args[:note])
      end
    end

    subject(:execute) { service.execute }

    context 'when current user is blank' do
      let(:current_user) { nil }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when user does not have permissions to create timeline events' do
      let(:current_user) { user_without_permissions }

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when feature is not available' do
      before do
        stub_licensed_features(incident_timeline_events: false)
      end

      it_behaves_like 'error response', 'You have insufficient permissions to manage timeline events for this incident'
    end

    context 'when error occurs during creation' do
      let(:args) { {} }

      it_behaves_like 'error response', "Occurred at can't be blank, Note can't be blank, and Note html can't be blank"
    end

    context 'with default action' do
      let(:args) { { 'note': 'note', 'occurred_at': Time.current } }

      it_behaves_like 'success response'

      it 'matches the default action', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(IncidentManagement::TimelineEvents::DEFAULT_ACTION)
      end
    end

    context 'with non_default action' do
      it_behaves_like 'success response'

      it 'matches the action from arguments', :aggregate_failures do
        result = execute.payload[:timeline_event]

        expect(result.action).to eq(args[:action])
      end
    end

    it 'successfully creates a database record', :aggregate_failures do
      expect { execute }.to change { ::IncidentManagement::TimelineEvent.count }.by(1)
    end
  end
end
