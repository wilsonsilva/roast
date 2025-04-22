# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require "vcr"
require "webmock/minitest"

###

begin
  addpath = lambda do |p|
    path = File.expand_path("../../#{p}", __FILE__)
    $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
  end
  addpath.call("lib")
end

require "roast"

require "cli/kit"

require "fileutils"
require "tmpdir"
require "tempfile"

require "rubygems"
require "bundler/setup"

CLI::UI::StdoutRouter.enable

require "minitest/autorun"
require "minitest/unit"
require "mocha/minitest"

require "vcr"
require "webmock/minitest"

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/vcr_cassettes"
  config.hook_into(:webmock)

  # Filter out sensitive data
  # config.filter_sensitive_data("<API_KEY>") { ENV["API_KEY"] }

  # Configure VCR to ignore certain hosts
  # config.ignore_hosts "localhost", "127.0.0.1"

  # Allow VCR to record real HTTP requests when no cassette exists
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body],
  }
end
