# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.runner(id)' do
  include GraphqlHelpers

  let_it_be(:admin) { create(:user, :admin) }

  shared_examples 'runner details fetch operation returning expected upgradeStatus' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, all_graphql_fields_for('CiRunner')))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    before do
      allow(::Gitlab::Ci::RunnerUpgradeCheck.instance)
        .to receive(:check_runner_upgrade_status)
        .and_return(upgrade_status)
        .once
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: current_user)

      runner_data = graphql_data_at(:runner)
      expect(runner_data).not_to be_nil

      expect(runner_data).to match a_hash_including(
        'id' => runner.to_global_id.to_s,
        'upgradeStatus' => expected_upgrade_status
      )
    end
  end

  describe 'upgradeStatus', :saas do
    let_it_be(:runner) { create(:ci_runner, description: 'Runner 1', version: 'adfe156', revision: 'a') }

    context 'requested by non-paid user' do
      let(:current_user) { admin }

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'UNKNOWN' } # non-paying users always see UNKNOWN

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested on an instance with runner_upgrade_management' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(runner_upgrade_management: true)
      end

      context 'with RunnerUpgradeCheck returning :error' do
        let(:upgrade_status) { :error }
        let(:expected_upgrade_status) { 'UNKNOWN' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested by paid user' do
      let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
      let_it_be(:user) { create(:user, :admin, namespace: create(:user_namespace)) }

      let(:current_user) { user }

      before do
        ultimate_group.add_reporter(user)
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end
  end
end
