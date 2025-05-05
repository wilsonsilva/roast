# frozen_string_literal: true

require "dotenv"
require "raix"
require "roast"
require "vcr"

Dotenv.load

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr" # the directory where your cassettes will be saved
  config.hook_into(:webmock)
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  config.default_cassette_options = {
    match_requests_on: [:method, :uri],
  }

  config.filter_sensitive_data("REDACTED") { |interaction| interaction.request.headers["Authorization"][0].sub("Bearer ", "") }
end

retry_options = {
  max: 2,
  interval: 0.05,
  interval_randomness: 0.5,
  backoff_factor: 2,
}

Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"], base_url: ENV["OPENAI_API_BASE"]) do |f|
    f.request(:retry, retry_options)
    f.response(:logger, Logger.new($stdout), { headers: true, bodies: true, errors: true }) do |logger|
      logger.filter(/(Bearer) (\S+)/, '\1[REDACTED]')
    end
  end
end

# Load support files
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # Include fixture helpers
  config.include(FixtureHelpers)
  config.include(TestFixtureHelpers)

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end

  config.before(:example, :novcr) do
    VCR.turn_off!
    WebMock.disable!
  end

  config.after(:example, :novcr) do
    VCR.turn_on!
    WebMock.enable!
  end

  # Ensure we're in a valid directory before each test
  config.before(:each) do
    @original_dir ||= Dir.pwd
  end

  # Restore directory after each test
  config.after(:each) do
    Dir.pwd
  rescue Errno::ENOENT
    # If current directory is invalid, restore to original
    Dir.chdir(@original_dir) if @original_dir && Dir.exist?(@original_dir)
  end
end
