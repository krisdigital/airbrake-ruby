RSpec.describe Airbrake::Config do
  let(:resolved_promise) { Airbrake::Promise.new.resolve }
  let(:rejected_promise) { Airbrake::Promise.new.reject }

  let(:valid_params) { { project_id: 1, project_key: '2' } }

  its(:project_id) { is_expected.to be_nil }
  its(:project_key) { is_expected.to be_nil }
  its(:logger) { is_expected.to be_a(Logger) }
  its(:app_version) { is_expected.to be_nil }
  its(:versions) { is_expected.to be_empty }
  its(:host) { is_expected.to eq('https://api.airbrake.io') }
  its(:endpoint) { is_expected.not_to be_nil }
  its(:workers) { is_expected.to eq(1) }
  its(:queue_size) { is_expected.to eq(100) }
  its(:root_directory) { is_expected.to eq(Bundler.root.realpath.to_s) }
  its(:environment) { is_expected.to be_nil }
  its(:ignore_environments) { is_expected.to be_empty }
  its(:timeout) { is_expected.to be_nil }
  its(:blacklist_keys) { is_expected.to be_empty }
  its(:whitelist_keys) { is_expected.to be_empty }
  its(:performance_stats) { is_expected.to eq(true) }
  its(:performance_stats_flush_period) { is_expected.to eq(15) }

  describe "#new" do
    context "when user config is passed" do
      subject { described_class.new(logger: StringIO.new) }
      its(:logger) { is_expected.to be_a(StringIO) }
    end
  end

  describe "#valid?" do
    context "when #validate returns a resolved promise" do
      before { expect(subject).to receive(:validate).and_return(resolved_promise) }
      it { is_expected.to be_valid }
    end

    context "when #validate returns a rejected promise" do
      before { expect(subject).to receive(:validate).and_return(rejected_promise) }
      it { is_expected.not_to be_valid }
    end
  end

  describe "#ignored_environment?" do
    context "when Validator returns a resolved promise" do
      before do
        expect(Airbrake::Config::Validator).to receive(:check_notify_ability)
          .and_return(resolved_promise)
      end

      its(:ignored_environment?) { is_expected.to be_falsey }
    end

    context "when Validator returns a rejected promise" do
      before do
        expect(Airbrake::Config::Validator).to receive(:check_notify_ability)
          .and_return(rejected_promise)
      end

      its(:ignored_environment?) { is_expected.to be_truthy }
    end
  end

  describe "#endpoint" do
    subject { described_class.new(valid_params.merge(user_config)) }

    context "when host ends with a URL with a slug with a trailing slash" do
      let(:user_config) { { host: 'https://localhost/bingo/' } }

      its(:endpoint) do
        is_expected.to eq(URI('https://localhost/bingo/api/v3/projects/1/notices'))
      end
    end

    context "when host ends with a URL with a slug without a trailing slash" do
      let(:user_config) { { host: 'https://localhost/bingo' } }

      its(:endpoint) do
        is_expected.to eq(URI('https://localhost/api/v3/projects/1/notices'))
      end
    end
  end

  describe "#validate" do
    its(:validate) { is_expected.to be_an(Airbrake::Promise) }
  end

  describe "#check_configuration" do
    let(:user_config) { {} }

    subject { described_class.new(valid_params.merge(user_config)) }

    its(:check_configuration) { is_expected.to be_an(Airbrake::Promise) }

    context "when config is invalid" do
      let(:user_config) { { project_id: nil } }
      its(:check_configuration) { is_expected.to be_rejected }
    end

    context "when current environment is ignored" do
      let(:user_config) { { environment: 'test', ignore_environments: ['test'] } }
      its(:check_configuration) { is_expected.to be_rejected }
    end

    context "when config is valid and allows notifying" do
      its(:check_configuration) { is_expected.not_to be_rejected }
    end
  end
end
