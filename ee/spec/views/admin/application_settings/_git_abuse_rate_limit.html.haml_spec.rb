# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/application_settings/_git_abuse_rate_limit' do
  let_it_be(:admin) { create(:admin) }

  before do
    assign(:application_setting, application_setting)
    allow(view).to receive(:current_user) { admin }
    allow(view).to receive(:expanded_by_default) { true }
  end

  describe 'git abuse rate limit settings' do
    before do
      stub_licensed_features(git_abuse_rate_limit: true)
      stub_feature_flags(git_abuse_rate_limit_feature_flag: true)
    end

    context 'when page loads' do
      let(:application_setting) { build(:application_setting) }

      it 'renders the settings app root' do
        render

        expect(rendered).to have_selector('#js-git-abuse-rate-limit-settings-form')

        expect(rendered).to have_selector('[data-max-number-of-repository-downloads="0"]')
        expect(rendered).to have_selector('[data-max-number-of-repository-downloads-within-time-period="0"]')
        expect(rendered).to have_selector('[data-git-rate-limit-users-allowlist="[]"]')
      end
    end

    context 'when data is saved in the database' do
      let(:allowlist) { %w[user1 user2] }
      let(:application_setting) do
        build(:application_setting,
              max_number_of_repository_downloads: 10,
              max_number_of_repository_downloads_within_time_period: 100,
              git_rate_limit_users_allowlist: allowlist
             )
      end

      it 'renders the settings app root with pre-saved data' do
        render

        expect(rendered).to have_selector('#js-git-abuse-rate-limit-settings-form')

        expect(rendered).to have_selector('[data-max-number-of-repository-downloads="10"]')
        expect(rendered).to have_selector('[data-max-number-of-repository-downloads-within-time-period="100"]')
        expect(rendered).to have_selector("[data-git-rate-limit-users-allowlist='#{allowlist}']")
      end
    end
  end
end
