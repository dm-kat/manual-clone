# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AutocompleteSourcesController do
  let_it_be(:group, reload: true) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  def members_by_username(username)
    json_response.find { |member| member['username'] == username }
  end

  describe 'GET members' do
    before do
      group.add_owner(user)
      sign_in(user)
    end

    it 'returns an array of member object' do
      get :members, format: :json, params: { namespace_id: group.path, project_id: project.path, type: issue.class.name, type_id: issue.id }

      expect(members_by_username('all').symbolize_keys).to include(
        username: 'all',
        name: 'All Project and Group Members',
        count: 1)

      expect(members_by_username(group.full_path).symbolize_keys).to include(
        type: group.class.name,
        name: group.full_name,
        avatar_url: group.avatar_url,
        count: 1)

      expect(members_by_username(user.username).symbolize_keys).to include(
        type: user.class.name,
        name: user.name,
        avatar_url: user.avatar_url)
    end
  end

  describe 'GET milestones' do
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, :public, namespace: group) }
    let!(:project_milestone) { create(:milestone, project: project) }
    let!(:group_milestone) { create(:milestone, group: group) }

    before do
      sign_in(user)
    end

    it 'lists milestones' do
      group.add_owner(user)

      get :milestones, format: :json, params: { namespace_id: group.path, project_id: project.path }

      milestone_titles = json_response.map { |milestone| milestone["title"] }
      expect(milestone_titles).to match_array([project_milestone.title, group_milestone.title])
    end

    context 'when user cannot read project issues and merge requests' do
      it 'renders 404' do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

        get :milestones, format: :json, params: { namespace_id: group.path, project_id: project.path }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET contacts' do
    let_it_be(:contact_1) { create(:contact, group: group) }
    let_it_be(:contact_2) { create(:contact, group: group) }

    before do
      sign_in(user)
    end

    context 'when feature flag is enabled' do
      context 'when a group has contact relations enabled' do
        before do
          create(:crm_settings, group: group, enabled: true)
        end

        context 'when a user can read contacts' do
          it 'lists contacts' do
            group.add_developer(user)

            get :contacts, format: :json, params: { namespace_id: group.path, project_id: project.path }

            emails = json_response.map { |contact_data| contact_data["email"] }
            expect(emails).to match_array([contact_1.email, contact_2.email])
          end
        end

        context 'when a user can not read contacts' do
          it 'renders 404' do
            get :contacts, format: :json, params: { namespace_id: group.path, project_id: project.path }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when a group has contact relations disabled' do
        it 'renders 404' do
          group.add_developer(user)

          get :contacts, format: :json, params: { namespace_id: group.path, project_id: project.path }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
