# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'view group invites' do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:not_authorized_group) { create(:group) }

  let(:dev_env_or_com) { true }

  before_all do
    group.add_owner(user)
  end

  before do
    login_as(user)
    allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
  end

  describe 'GET /users/sign_up/group_invites/new' do
    subject(:get_request) { get new_users_sign_up_group_invite_path(group_params) }

    let(:group_params) { { group_id: group.id } }

    context 'with an authorized user' do
      it 'returns 200 response' do
        get_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when not on .com' do
      let(:dev_env_or_com) { false }

      it 'returns not_found' do
        get_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not authorized to invite for the group' do
      let(:group_params) { { group_id: not_authorized_group.id } }

      it 'returns not_found' do
        get_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /users/sign_up/group_invites' do
    subject(:post_request) { post users_sign_up_group_invites_path(group_params) }

    let(:group_params) { { group_id: group.id } }

    context 'with an authorized user' do
      specify do
        is_expected.to redirect_to(new_users_sign_up_project_path(namespace_id: group.id,
                                                                  trial: false,
                                                                  trial_onboarding_flow: false,
                                                                  hide_trial_activation_banner: true))
      end

      context 'when inviting members', :experiment do
        it 'tracks for the force_company_trial experiment' do
          expect(experiment(:force_company_trial)).to track(:create_invite, namespace: group, user: user)
                                                        .with_context(user: user)
                                                        .on_next_instance

          post_request
        end

        context 'without valid emails in the params' do
          it 'no invites generated by default' do
            post_request

            expect(group.members.invite).to be_empty
          end
        end

        context 'with valid emails in the params' do
          let(:valid_emails) { %w[a@a.a b@b.b] }
          let(:group_params) { { group_id: group.id, emails: valid_emails + ['', '', 'x', 'y'] } }

          it 'adds users with developer access and ignores blank and invalid emails', :aggregate_failures, :snowplow do
            post_request

            invited_members = group.members.invite
            expect(invited_members.pluck(:invite_email)).to match_array(valid_emails)
            expect(invited_members.pluck(:access_level).uniq).to match([Gitlab::Access::DEVELOPER])
            expect_snowplow_event(
              category: 'Members::CreateService',
              action: 'create_member',
              label: 'registrations-group-invite',
              property: 'net_new_user',
              user: user
            )
          end
        end
      end

      context 'when considering trial parameters' do
        let(:group_params) { { group_id: group.id, trial: true, trial_onboarding_flow: true } }

        specify do
          is_expected.to redirect_to(new_users_sign_up_project_path(namespace_id: group.id,
                                                                    trial: true,
                                                                    trial_onboarding_flow: true,
                                                                    hide_trial_activation_banner: true))
        end
      end
    end

    context 'when not on .com' do
      let(:dev_env_or_com) { false }

      it 'returns not_found' do
        post_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is not authorized to invite for the group' do
      let(:group_params) { { group_id: not_authorized_group.id } }

      it 'returns not_found' do
        post_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
