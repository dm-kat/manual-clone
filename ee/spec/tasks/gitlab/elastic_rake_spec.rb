# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:elastic namespace rake tasks', :elastic do
  before do
    Rake.application.rake_require 'tasks/gitlab/elastic'
  end

  describe 'create_empty_index' do
    subject { run_rake_task('gitlab:elastic:create_empty_index') }

    before do
      es_helper.delete_index
      es_helper.delete_index(index_name: es_helper.migrations_index_name)
    end

    it 'creates an index' do
      expect { subject }.to change { es_helper.index_exists? }.from(false).to(true)
    end

    it 'marks all migrations as completed' do
      expect(Elastic::DataMigrationService).to receive(:mark_all_as_completed!).and_call_original
      expect(Elastic::MigrationRecord.persisted_versions(completed: true)).to eq([])

      subject
      refresh_index!

      migrations = Elastic::DataMigrationService.migrations.map(&:version)
      expect(Elastic::MigrationRecord.persisted_versions(completed: true)).to eq(migrations)
    end
  end

  describe 'delete_index' do
    subject { run_rake_task('gitlab:elastic:delete_index') }

    it 'removes the index' do
      expect { subject }.to change { es_helper.index_exists? }.from(true).to(false)
    end
  end

  context "with elasticsearch_indexing enabled" do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    describe 'index' do
      it 'calls all indexing tasks in order' do
        expect(Rake::Task['gitlab:elastic:recreate_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:clear_index_status']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_projects']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_snippets']).to receive(:invoke).ordered

        run_rake_task 'gitlab:elastic:index'
      end
    end

    describe 'index_projects' do
      let(:project1) { create :project }
      let(:project2) { create :project }
      let(:project3) { create :project }

      before do
        Sidekiq::Testing.disable! do
          project1
          project2
        end
      end

      it 'queues jobs for each project batch' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1, project2)

        run_rake_task 'gitlab:elastic:index_projects'
      end

      context 'with limited indexing enabled' do
        before do
          Sidekiq::Testing.disable! do
            project1
            project2
            project3

            create :elasticsearch_indexed_project, project: project1
            create :elasticsearch_indexed_namespace, namespace: project3.namespace
          end

          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'does not queue jobs for projects that should not be indexed' do
          expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1, project3)

          run_rake_task 'gitlab:elastic:index_projects'
        end
      end
    end

    describe 'index_snippets' do
      it 'indexes snippets' do
        expect(Snippet).to receive(:es_import)

        run_rake_task 'gitlab:elastic:index_snippets'
      end
    end

    describe 'recreate_index' do
      it 'calls all related subtasks in order' do
        expect(Rake::Task['gitlab:elastic:delete_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:create_empty_index']).to receive(:invoke).ordered

        run_rake_task 'gitlab:elastic:recreate_index'
      end
    end
  end

  context "with elasticsearch_indexing is disabled" do
    it 'enables `elasticsearch_indexing`' do
      expect { run_rake_task 'gitlab:elastic:index' }.to change {
        Gitlab::CurrentSettings.elasticsearch_indexing?
      }.from(false).to(true)
    end
  end

  describe 'mark_reindex_failed' do
    subject { run_rake_task('gitlab:elastic:mark_reindex_failed') }

    context 'when there is a running reindex job' do
      before do
        Elastic::ReindexingTask.create!
      end

      it 'marks the current reindex job as failed' do
        expect { subject }.to change {Elastic::ReindexingTask.running?}.from(true).to(false)
      end

      it 'prints a message after marking it as failed' do
        expect { subject }.to output("Marked the current reindexing job as failed.\n").to_stdout
      end
    end

    context 'when no running reindex job' do
      it 'just prints a message' do
        expect { subject }.to output("Did not find the current running reindexing job.\n").to_stdout
      end
    end
  end
end
