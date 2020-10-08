# frozen_string_literal: true

module IncidentManagement
  class CreateIncidentSlaExceededLabelService < BaseService
    LABEL_PROPERTIES = {
      title: 'missed::SLA',
      color: '#D9534F',
      description: <<~DESCRIPTION.chomp
        Incidents that have missed the targeted SLA (Service Level Agreement).
      DESCRIPTION
    }.freeze

    def execute
      label = Labels::FindOrCreateService
        .new(current_user, project, **LABEL_PROPERTIES)
        .execute(skip_authorization: true)

      ServiceResponse.success(payload: { label: label })
    end
  end
end
