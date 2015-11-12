require 'spec_helper'
require 'mime/types'

describe API::API, api: true  do
  include ApiHelpers
  include RepoHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id) }
  let!(:master) { create(:project_member, user: user, project: project, access_level: ProjectMember::MASTER) }
  let!(:guest) { create(:project_member, user: user2, project: project, access_level: ProjectMember::GUEST) }


  describe "GET /projects/:id/repository/tags" do
    it "should return an array of project tags" do
      get api("/projects/#{project.id}/repository/tags", user)
      expect(response.status).to eq(200)
      expect(json_response).to be_an Array
      expect(json_response.first['name']).to eq(project.repo.tags.sort_by(&:name).reverse.first.name)
    end
  end

  describe 'POST /projects/:id/repository/tags' do
    context 'lightweight tags' do
      it 'should create a new tag' do
        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.0.1',
             ref: 'master'

        expect(response.status).to eq(201)
        expect(json_response['name']).to eq('v7.0.1')
      end
    end

    context 'annotated tag' do
      it 'should create a new annotated tag' do
        # Identity must be set in .gitconfig to create annotated tag.
        repo_path = project.repository.path_to_repo
        system(*%W(#{Gitlab.config.git.bin_path} --git-dir=#{repo_path} config user.name #{user.name}))
        system(*%W(#{Gitlab.config.git.bin_path} --git-dir=#{repo_path} config user.email #{user.email}))

        post api("/projects/#{project.id}/repository/tags", user),
             tag_name: 'v7.1.0',
             ref: 'master',
             message: 'Release 7.1.0'

        expect(response.status).to eq(201)
        expect(json_response['name']).to eq('v7.1.0')
        expect(json_response['message']).to eq('Release 7.1.0')
      end
    end

    it 'should deny for user without push access' do
      post api("/projects/#{project.id}/repository/tags", user2),
           tag_name: 'v1.9.0',
           ref: '621491c677087aa243f165eab467bfdfbee00be1'
      expect(response.status).to eq(403)
    end

    it 'should return 400 if tag name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v 1.0.0',
           ref: 'master'
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Tag name invalid')
    end

    it 'should return 400 if tag already exists' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      expect(response.status).to eq(201)
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'v8.0.0',
           ref: 'master'
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Tag already exists')
    end

    it 'should return 400 if ref name is invalid' do
      post api("/projects/#{project.id}/repository/tags", user),
           tag_name: 'mytag',
           ref: 'foo'
      expect(response.status).to eq(400)
      expect(json_response['message']).to eq('Invalid reference name')
    end
  end
end
