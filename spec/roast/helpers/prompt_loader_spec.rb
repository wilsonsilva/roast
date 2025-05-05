# frozen_string_literal: true

require "spec_helper"
require "roast/helpers/prompt_loader"

RSpec.describe(Roast::Helpers::PromptLoader) do
  let(:workflow_file) { test_fixture_file("workflow/workflow.yml") }
  let(:test_file) { test_fixture_file("test.rb") }

  # Create a minimal workflow object that provides what PromptLoader needs
  let(:workflow) do
    parser = Roast::Workflow::ConfigurationParser.new(workflow_file, [test_file])
    # Don't actually execute the workflow, just set it up
    parser.instance_variable_set(
      :@current_workflow,
      Roast::Workflow::BaseWorkflow.new(
        test_file,
        name: "workflow",
        context_path: File.dirname(workflow_file),
      ),
    )
    parser.current_workflow
  end

  describe ".load_prompt" do
    it "loads basic prompt file" do
      result = described_class.load_prompt(workflow, test_file)
      expect(result).to(start_with("As a senior Ruby engineer and testing expert"))
    end

    context "with alternate file extension" do
      let(:test_file) { test_fixture_file("test.ts") }

      it "loads alternate prompt file based on extension" do
        result = described_class.load_prompt(workflow, test_file)
        expect(result).to(start_with("As a senior front-end engineer and testing expert"))
      end
    end

    it "processes erb if needed" do
      result = described_class.load_prompt(workflow, test_file)
      expect(result).to(include("class RoastTest < Minitest::Test"))
    end
  end
end
