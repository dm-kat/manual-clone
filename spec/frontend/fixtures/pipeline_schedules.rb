# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineSchedulesController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' ) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.first_owner }
  let!(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project, owner: user) }
  let!(:pipeline_schedule_populated) { create(:ci_pipeline_schedule, project: project, owner: user) }
  let!(:pipeline_schedule_variable1) { create(:ci_pipeline_schedule_variable, key: 'foo', value: 'foovalue', pipeline_schedule: pipeline_schedule_populated) }
  let!(:pipeline_schedule_variable2) { create(:ci_pipeline_schedule_variable, key: 'bar', value: 'barvalue', pipeline_schedule: pipeline_schedule_populated) }

  render_views

  before do
    sign_in(user)
  end

  it 'pipeline_schedules/edit.html' do
    get :edit, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: pipeline_schedule.id
    }

    expect(response).to be_successful
  end

  it 'pipeline_schedules/edit_with_variables.html' do
    get :edit, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: pipeline_schedule_populated.id
    }

    expect(response).to be_successful
  end
end
