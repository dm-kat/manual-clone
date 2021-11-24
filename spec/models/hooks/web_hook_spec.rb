# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHook do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }

  let(:hook) { build(:project_hook, project: project) }

  around do |example|
    if example.metadata[:skip_freeze_time]
      example.run
    else
      freeze_time { example.run }
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:web_hook_logs) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:url) }

    describe 'url' do
      it { is_expected.to allow_value('http://example.com').for(:url) }
      it { is_expected.to allow_value('https://example.com').for(:url) }
      it { is_expected.to allow_value(' https://example.com ').for(:url) }
      it { is_expected.to allow_value('http://test.com/api').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc').for(:url) }
      it { is_expected.to allow_value('http://test.com/api?key=abc&type=def').for(:url) }

      it { is_expected.not_to allow_value('example.com').for(:url) }
      it { is_expected.not_to allow_value('ftp://example.com').for(:url) }
      it { is_expected.not_to allow_value('herp-and-derp').for(:url) }

      context 'when url is local' do
        let(:url) { 'http://localhost:9000' }

        it { is_expected.not_to allow_value(url).for(:url) }

        it 'is valid if application settings allow local requests from web hooks' do
          settings = ApplicationSetting.new(allow_local_requests_from_web_hooks_and_services: true)
          allow(ApplicationSetting).to receive(:current).and_return(settings)

          is_expected.to allow_value(url).for(:url)
        end
      end

      it 'strips :url before saving it' do
        hook.url = ' https://example.com '
        hook.save!

        expect(hook.url).to eq('https://example.com')
      end
    end

    describe 'token' do
      it { is_expected.to allow_value("foobar").for(:token) }

      it { is_expected.not_to allow_values("foo\nbar", "foo\r\nbar").for(:token) }
    end

    describe 'push_events_branch_filter' do
      it { is_expected.to allow_values("good_branch_name", "another/good-branch_name").for(:push_events_branch_filter) }
      it { is_expected.to allow_values("").for(:push_events_branch_filter) }
      it { is_expected.not_to allow_values("bad branch name", "bad~branchname").for(:push_events_branch_filter) }

      it 'gets rid of whitespace' do
        hook.push_events_branch_filter = ' branch '
        hook.save!

        expect(hook.push_events_branch_filter).to eq('branch')
      end

      it 'stores whitespace only as empty' do
        hook.push_events_branch_filter = ' '
        hook.save!

        expect(hook.push_events_branch_filter).to eq('')
      end
    end
  end

  describe 'encrypted attributes' do
    subject { described_class.encrypted_attributes.keys }

    it { is_expected.to contain_exactly(:token, :url) }
  end

  describe 'execute' do
    let(:data) { { key: 'value' } }
    let(:hook_name) { 'project hook' }

    it '#execute' do
      expect_next(WebHookService).to receive(:execute)

      hook.execute(data, hook_name)
    end

    it 'does not execute non-executable hooks' do
      hook.update!(disabled_until: 1.day.from_now)

      expect(WebHookService).not_to receive(:new)

      hook.execute(data, hook_name)
    end

    it '#async_execute' do
      expect_next(WebHookService).to receive(:async_execute)

      hook.async_execute(data, hook_name)
    end

    it 'does not async execute non-executable hooks' do
      hook.update!(disabled_until: 1.day.from_now)

      expect(WebHookService).not_to receive(:new)

      hook.async_execute(data, hook_name)
    end
  end

  describe '#destroy' do
    it 'cascades to web_hook_logs' do
      web_hook = create(:project_hook)
      create_list(:web_hook_log, 3, web_hook: web_hook)

      expect { web_hook.destroy! }.to change(web_hook.web_hook_logs, :count).by(-3)
    end
  end

  describe '.executable' do
    let(:not_executable) do
      [
        [0, Time.current],
        [0, 1.minute.from_now],
        [1, 1.minute.from_now],
        [3, 1.minute.from_now],
        [4, nil],
        [4, 1.day.ago],
        [4, 1.minute.from_now]
      ].map do |(recent_failures, disabled_until)|
        create(:project_hook, project: project, recent_failures: recent_failures, disabled_until: disabled_until)
      end
    end

    let(:executables) do
      [
        [0, nil],
        [0, 1.day.ago],
        [1, nil],
        [1, 1.day.ago],
        [3, nil],
        [3, 1.day.ago]
      ].map do |(recent_failures, disabled_until)|
        create(:project_hook, project: project, recent_failures: recent_failures, disabled_until: disabled_until)
      end
    end

    it 'finds the correct set of project hooks' do
      expect(described_class.where(project_id: project.id).executable).to match_array executables
    end

    context 'when the feature flag is not enabled' do
      before do
        stub_feature_flags(web_hooks_disable_failed: false)
      end

      it 'is the same as all' do
        expect(described_class.where(project_id: project.id).executable).to match_array(executables + not_executable)
      end
    end
  end

  describe '#executable?' do
    let(:web_hook) { create(:project_hook, project: project) }

    where(:recent_failures, :not_until, :executable) do
      [
        [0, :not_set, true],
        [0, :past,    true],
        [0, :future,  false],
        [0, :now,     false],
        [1, :not_set, true],
        [1, :past,    true],
        [1, :future,  false],
        [3, :not_set, true],
        [3, :past,    true],
        [3, :future,  false],
        [4, :not_set, false],
        [4, :past,    false],
        [4, :future,  false]
      ]
    end

    with_them do
      # Phasing means we cannot put these values in the where block,
      # which is not subject to the frozen time context.
      let(:disabled_until) do
        case not_until
        when :not_set
          nil
        when :past
          1.minute.ago
        when :future
          1.minute.from_now
        when :now
          Time.current
        end
      end

      before do
        web_hook.update!(recent_failures: recent_failures, disabled_until: disabled_until)
      end

      it 'has the correct state' do
        expect(web_hook.executable?).to eq(executable)
      end

      context 'when the feature flag is enabled for a project' do
        before do
          stub_feature_flags(web_hooks_disable_failed: project)
        end

        it 'has the expected value' do
          expect(web_hook.executable?).to eq(executable)
        end
      end

      context 'when the feature flag is not enabled' do
        before do
          stub_feature_flags(web_hooks_disable_failed: false)
        end

        it 'is executable' do
          expect(web_hook).to be_executable
        end
      end
    end
  end

  describe '#next_backoff' do
    context 'when there was no last backoff' do
      before do
        hook.backoff_count = 0
      end

      it 'is 10 minutes' do
        expect(hook.next_backoff).to eq(described_class::INITIAL_BACKOFF)
      end
    end

    context 'when we have backed off once' do
      before do
        hook.backoff_count = 1
      end

      it 'is twice the initial value' do
        expect(hook.next_backoff).to eq(20.minutes)
      end
    end

    context 'when we have backed off 3 times' do
      before do
        hook.backoff_count = 3
      end

      it 'grows exponentially' do
        expect(hook.next_backoff).to eq(80.minutes)
      end
    end

    context 'when the previous backoff was large' do
      before do
        hook.backoff_count = 8 # last value before MAX_BACKOFF
      end

      it 'does not exceed the max backoff value' do
        expect(hook.next_backoff).to eq(described_class::MAX_BACKOFF)
      end
    end
  end

  shared_examples 'is tolerant of invalid records' do
    specify do
      hook.url = nil

      expect(hook).to be_invalid
      run_expectation
    end
  end

  describe '#enable!' do
    it 'makes a hook executable if it was marked as failed' do
      hook.recent_failures = 1000

      expect { hook.enable! }.to change(hook, :executable?).from(false).to(true)
    end

    it 'makes a hook executable if it is currently backed off' do
      hook.disabled_until = 1.hour.from_now

      expect { hook.enable! }.to change(hook, :executable?).from(false).to(true)
    end

    it 'does not update hooks unless necessary' do
      sql_count = ActiveRecord::QueryRecorder.new { hook.enable! }.count

      expect(sql_count).to eq(0)
    end

    include_examples 'is tolerant of invalid records' do
      def run_expectation
        hook.recent_failures = 1000

        expect { hook.enable! }.to change(hook, :executable?).from(false).to(true)
      end
    end
  end

  describe 'backoff!' do
    it 'sets disabled_until to the next backoff' do
      expect { hook.backoff! }.to change(hook, :disabled_until).to(hook.next_backoff.from_now)
    end

    it 'increments the backoff count' do
      expect { hook.backoff! }.to change(hook, :backoff_count).by(1)
    end

    context 'when we have backed off MAX_FAILURES times' do
      before do
        stub_const("#{described_class}::MAX_FAILURES", 5)
        5.times { hook.backoff! }
      end

      it 'does not let the backoff count exceed the maximum failure count' do
        expect { hook.backoff! }.not_to change(hook, :backoff_count)
      end

      it 'does not change disabled_until', :skip_freeze_time do
        travel_to(hook.disabled_until - 1.minute) do
          expect { hook.backoff! }.not_to change(hook, :disabled_until)
        end
      end

      it 'changes disabled_until when it has elapsed', :skip_freeze_time do
        travel_to(hook.disabled_until + 1.minute) do
          expect { hook.backoff! }.to change { hook.disabled_until }
          expect(hook.backoff_count).to eq(described_class::MAX_FAILURES)
        end
      end
    end

    include_examples 'is tolerant of invalid records' do
      def run_expectation
        expect { hook.backoff! }.to change(hook, :backoff_count).by(1)
      end
    end
  end

  describe 'failed!' do
    it 'increments the failure count' do
      expect { hook.failed! }.to change(hook, :recent_failures).by(1)
    end

    it 'does not update the hook if the the failure count exceeds the maximum value' do
      hook.recent_failures = described_class::MAX_FAILURES

      sql_count = ActiveRecord::QueryRecorder.new { hook.failed! }.count

      expect(sql_count).to eq(0)
    end

    include_examples 'is tolerant of invalid records' do
      def run_expectation
        expect { hook.failed! }.to change(hook, :recent_failures).by(1)
      end
    end
  end

  describe '#disable!' do
    it 'disables a hook' do
      expect { hook.disable! }.to change(hook, :executable?).from(true).to(false)
    end

    include_examples 'is tolerant of invalid records' do
      def run_expectation
        expect { hook.disable! }.to change(hook, :executable?).from(true).to(false)
      end
    end
  end

  describe '#temporarily_disabled?' do
    it 'is false when not temporarily disabled' do
      expect(hook).not_to be_temporarily_disabled
    end

    context 'when hook has been told to back off' do
      before do
        hook.backoff!
      end

      it 'is true' do
        expect(hook).to be_temporarily_disabled
      end

      it 'is false when `web_hooks_disable_failed` flag is disabled' do
        stub_feature_flags(web_hooks_disable_failed: false)

        expect(hook).not_to be_temporarily_disabled
      end
    end
  end

  describe '#permanently_disabled?' do
    it 'is false when not disabled' do
      expect(hook).not_to be_permanently_disabled
    end

    context 'when hook has been disabled' do
      before do
        hook.disable!
      end

      it 'is true' do
        expect(hook).to be_permanently_disabled
      end

      it 'is false when `web_hooks_disable_failed` flag is disabled' do
        stub_feature_flags(web_hooks_disable_failed: false)

        expect(hook).not_to be_permanently_disabled
      end
    end
  end

  describe '#rate_limited?' do
    context 'when there are rate limits' do
      before do
        allow(hook).to receive(:rate_limit).and_return(3)
      end

      it 'is false when hook has not been rate limited' do
        expect(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(false)
        expect(hook).not_to be_rate_limited
      end

      it 'is true when hook has been rate limited' do
        expect(Gitlab::ApplicationRateLimiter).to receive(:peek).and_return(true)
        expect(hook).to be_rate_limited
      end
    end

    context 'when there are no rate limits' do
      before do
        allow(hook).to receive(:rate_limit).and_return(nil)
      end

      it 'does not call Gitlab::ApplicationRateLimiter, and is false' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:peek)
        expect(hook).not_to be_rate_limited
      end
    end
  end
end
