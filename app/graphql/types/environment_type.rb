# frozen_string_literal: true

module Types
  class EnvironmentType < BaseObject
    graphql_name 'Environment'
    description 'Describes where code is deployed for a project'

    present_using ::EnvironmentPresenter

    authorize :read_environment

    field :name, GraphQL::Types::String, null: false,
                                         description: 'Human-readable name of the environment.'

    field :id, GraphQL::Types::ID, null: false,
                                   description: 'ID of the environment.'

    field :state, GraphQL::Types::String, null: false,
                                          description: 'State of the environment, for example: available/stopped.'

    field :path, GraphQL::Types::String, null: false,
                                         description: 'Path to the environment.'

    field :external_url, GraphQL::Types::String, null: true,
                                                 description: 'External URL of the environment.'

    field :metrics_dashboard, Types::Metrics::DashboardType, null: true,
                                                             description: 'Metrics dashboard schema for the environment.',
                                                             resolver: Resolvers::Metrics::DashboardResolver

    field :latest_opened_most_severe_alert,
          Types::AlertManagement::AlertType,
          null: true,
          description: 'Most severe open alert for the environment. If multiple alerts have equal severity, the most recent is returned.'

    # Setting high complexity for preventing users from querying deployments for multiple environments,
    # which could result in N+1 issue.
    field :deployments,
          Types::DeploymentType.connection_type,
          null: true,
          description: 'Deployments of the environment.',
          resolver: Resolvers::DeploymentsResolver,
          complexity: 150
  end
end
