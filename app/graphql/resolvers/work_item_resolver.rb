# frozen_string_literal: true

module Resolvers
  class WorkItemResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorize :read_work_item

    type Types::WorkItemType, null: true

    argument :id, ::Types::GlobalIDType[::WorkItem], required: true, description: 'Global ID of the work item.'

    def resolve(id:)
      work_item = authorized_find!(id: id)
      return unless work_item.project.work_items_feature_flag_enabled?

      work_item
    end

    private

    def find_object(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end
