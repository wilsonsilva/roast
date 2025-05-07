# frozen_string_literal: true

require "spec_helper"
require "roast/workflow/configuration"

RSpec.describe(Roast::Workflow::Configuration) do
  let(:workflow_path) { fixture_file("valid_workflow.yml") }
  let(:options) { {} }
  let(:configuration) { described_class.new(workflow_path, options) }

  describe "#initialize" do
    it "loads configuration from YAML file" do
      expect(configuration.name).to(eq("My Workflow"))
      expect(configuration.steps).to(be_an(Array))
      expect(configuration.tools).to(be_an(Array))
    end

    context "when target is provided" do
      context "with shell command syntax" do
        let(:workflow_path) { fixture_file("workflow_with_shell_target.yml") }

        it "processes shell command target" do
          expect(configuration.target).to(eq("test.rb"))
        end
      end

      context "with glob pattern" do
        let(:workflow_path) { fixture_file("workflow_with_glob_target.yml") }

        it "expands glob patterns" do
          expect(configuration.target).to(include("_spec.rb"))
        end
      end
    end

    context "when api_token is provided" do
      # Create a temporary workflow file with api_token
      let(:workflow_path) { fixture_file("workflow_with_api_token.yml") }

      before do
        # Create fixture with api_token
        File.write(workflow_path, {
          "name" => "Workflow with API Token",
          "steps" => ["step1"],
          "api_token" => "$(echo test_token)",
        }.to_yaml)

        # Stub Open3 to return a test token
        allow(Open3).to(receive(:capture2e).with({}, "echo test_token").and_return(["test_token\n", double(success?: true)]))
      end

      after do
        File.delete(workflow_path) if File.exist?(workflow_path)
      end

      it "processes shell command to get api_token" do
        expect(configuration.api_token).to(eq("test_token"))
      end
    end
  end

  describe "#find_step_index" do
    let(:steps) { ["step1", { "var1" => "step2" }, ["step3", "step4"]] }

    it "finds index of simple string steps" do
      expect(configuration.find_step_index(steps, "step1")).to(eq(0))
    end

    it "finds index of hash steps" do
      expect(configuration.find_step_index(steps, "var1")).to(eq(1))
    end

    it "finds index within parallel steps" do
      expect(configuration.find_step_index(steps, "step3")).to(eq(2))
      expect(configuration.find_step_index(steps, "step4")).to(eq(2))
    end

    it "returns nil for non-existent steps" do
      expect(configuration.find_step_index(steps, "nonexistent")).to(be_nil)
    end
  end

  describe "#function_config" do
    context "when functions are configured" do
      let(:workflow_path) { fixture_file("workflow_with_functions.yml") }

      before do
        # Create fixture with functions configuration
        File.write(workflow_path, {
          "name" => "Workflow with Functions",
          "steps" => ["step1"],
          "functions" => {
            "grep" => { "cache" => { "enabled" => true } },
          },
        }.to_yaml)
      end

      after do
        File.delete(workflow_path) if File.exist?(workflow_path)
      end

      it "returns configuration for existing function" do
        expect(configuration.function_config("grep")).to(eq({ "cache" => { "enabled" => true } }))
      end

      it "returns empty hash for non-existing function" do
        expect(configuration.function_config("nonexistent")).to(eq({}))
      end
    end
  end
end
