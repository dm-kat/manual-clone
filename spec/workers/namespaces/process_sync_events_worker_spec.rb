# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ProcessSyncEventsWorker do
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group) }
  let!(:group3) { create(:group) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  describe '#perform' do
    subject(:perform) { worker.perform }

    before do
      group2.update!(parent: group1)
      group3.update!(parent: group2)
    end

    it 'consumes all sync events' do
      expect { perform }.to change(Namespaces::SyncEvent, :count).from(5).to(0)
    end

    it 'syncs namespace hierarchy traversal ids' do
      expect { perform }.to change(Ci::NamespaceMirror, :all).to contain_exactly(
        an_object_having_attributes(namespace_id: group1.id, traversal_ids: [group1.id]),
        an_object_having_attributes(namespace_id: group2.id, traversal_ids: [group1.id, group2.id]),
        an_object_having_attributes(namespace_id: group3.id, traversal_ids: [group1.id, group2.id, group3.id])
      )
    end

    it 'logs the service result', :aggregate_failures do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:estimated_total_events, 5)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:consumable_events, 5)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:processed_events, 5)

      perform
    end
  end
end
