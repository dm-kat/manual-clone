# frozen_string_literal: true

module QA
  RSpec.shared_context 'with gitlab project migration' do
    let(:source_project_with_readme) { false }
    let(:import_wait_duration) { { max_duration: 300, sleep_interval: 2 } }
    let(:admin_api_client) { Runtime::API::Client.as_admin }
    let(:user) do
      Resource::User.fabricate_via_api! do |usr|
        usr.api_client = admin_api_client
        usr.hard_delete_on_api_removal = true
      end
    end

    let(:api_client) { Runtime::API::Client.new(user: user) }

    let(:sandbox) do
      Resource::Sandbox.fabricate_via_api! do |group|
        group.api_client = admin_api_client
      end
    end

    let(:source_group) do
      Resource::Sandbox.fabricate_via_api! do |group|
        group.api_client = api_client
        group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
      end
    end

    let(:source_project) do
      Resource::Project.fabricate_via_api! do |project|
        project.api_client = api_client
        project.group = source_group
        project.initialize_with_readme = source_project_with_readme
      end
    end

    let(:imported_group) do
      Resource::BulkImportGroup.fabricate_via_api! do |group|
        group.api_client = api_client
        group.sandbox = sandbox
        group.source_group_path = source_group.path
      end
    end

    let(:imported_projects) { imported_group.reload!.projects }
    let(:imported_project) { imported_projects.first }

    let(:import_failures) do
      imported_group.import_details.sum([]) { |details| details[:failures] }
    end

    def expect_import_finished
      imported_group # trigger import

      expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)
      expect(imported_projects.count).to eq(1), 'Expected to have 1 imported project'
    end

    before do
      Runtime::Feature.enable(:bulk_import_projects)

      sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      source_project # fabricate source group and project
    end

    after do |example|
      # Checking for failures in the test currently makes test very flaky
      # Just log in case of failure until cause of network errors is found
      Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?

      user.remove_via_api!
    ensure
      Runtime::Feature.disable(:bulk_import_projects)
    end
  end
end
