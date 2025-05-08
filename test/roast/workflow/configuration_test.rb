# frozen_string_literal: true

require "minitest/autorun"
require "yaml"
require "open3"
require "roast/workflow/configuration"
require_relative "../../support/fixture_helpers"

class RoastWorkflowConfigurationTest < Minitest::Test
  def setup
    @options = {}
  end

  def test_loads_configuration_from_yaml_file
    workflow_path = fixture_file("valid_workflow.yml")
    configuration = Roast::Workflow::Configuration.new(workflow_path, @options)
    assert_equal("My Workflow", configuration.name)
    assert_kind_of(Array, configuration.steps)
    assert_kind_of(Array, configuration.tools)
  end

  def test_processes_shell_command_target
    workflow_path = fixture_file("workflow_with_shell_target.yml")
    configuration = Roast::Workflow::Configuration.new(workflow_path, @options)
    assert_includes(configuration.target, "test.rb")
  end

  def test_expands_glob_patterns
    workflow_path = fixture_file("workflow_with_glob_target.yml")
    configuration = Roast::Workflow::Configuration.new(workflow_path, @options)
    assert_includes(configuration.target, "*_spec.rb")
  end

  def test_processes_shell_command_to_get_api_token
    workflow_path = fixture_file("workflow_with_api_token.yml")
    # Create fixture with api_token
    File.write(workflow_path, {
      "name" => "Workflow with API Token",
      "steps" => ["step1"],
      "api_token" => "$(echo test_token)",
    }.to_yaml)

    # Stub Open3.capture2e
    Open3.stub(:capture2e, ["test_token\n", Minitest::Mock.new.expect(:success?, true)]) do
      configuration = Roast::Workflow::Configuration.new(workflow_path, @options)
      assert_equal("test_token", configuration.api_token)
    end
  ensure
    File.delete(workflow_path) if workflow_path && File.exist?(workflow_path)
  end

  class FunctionConfigTest < Minitest::Test
    include FixtureHelpers
    def setup
      @workflow_path = fixture_file("workflow_with_functions.yml")
      File.write(@workflow_path, {
        "name" => "Workflow with Functions",
        "steps" => ["step1"],
        "functions" => {
          "grep" => { "cache" => { "enabled" => true } },
        },
      }.to_yaml)
      @options = {}
      @configuration = Roast::Workflow::Configuration.new(@workflow_path, @options)
    end

    def teardown
      File.delete(@workflow_path) if @workflow_path && File.exist?(@workflow_path)
    end

    def test_returns_configuration_for_existing_function
      assert_equal({ "cache" => { "enabled" => true } }, @configuration.function_config("grep"))
    end

    def test_returns_empty_hash_for_non_existing_function
      assert_equal({}, @configuration.function_config("nonexistent"))
    end
  end
end
