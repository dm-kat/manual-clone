# frozen_string_literal: true

module API
  module Admin
    class BatchedBackgroundMigrations < ::API::Base
      feature_category :database
      urgency :low

      before do
        authenticated_as_admin!
      end

      namespace 'admin' do
        resources 'batched_background_migrations' do
          desc 'Get the list of the batched background migrations'
          params do
            optional :database,
              type: String,
              values: Gitlab::Database.all_database_names,
              desc: 'The name of the database, the default `main`',
              default: 'main'
          end
          get do
            Gitlab::Database::SharedModel.using_connection(base_model.connection) do
              migrations = Database::BatchedBackgroundMigrationsFinder.new(connection: base_model.connection).execute
              present_entity(migrations)
            end
          end
        end
      end

      helpers do
        def base_model
          database = params[:database] || Gitlab::Database::MAIN_DATABASE_NAME
          @base_model ||= Gitlab::Database.database_base_models[database]
        end

        def present_entity(result)
          present result,
            with: ::API::Entities::BatchedBackgroundMigration
        end
      end
    end
  end
end
