# frozen_string_literal: true

require "spec_helper"
require "roast/workflow/base_step"
require "roast/workflow/base_workflow"

RSpec.describe(Roast::Workflow::BaseStep) do
  let(:file) { test_fixture_file("test.rb") }
  let(:workflow) { Roast::Workflow::BaseWorkflow.new(file) }
  let(:step) { described_class.new(workflow) }

  describe "#initialize" do
    it "sets workflow and default model" do
      expect(step.workflow).to(eq(workflow))
      expect(step.model).to(eq("anthropic:claude-3-7-sonnet"))
    end

    it "accepts custom model" do
      custom_model = "gpt-4"
      step_with_custom_model = described_class.new(workflow, model: custom_model)
      expect(step_with_custom_model.model).to(eq(custom_model))
    end
  end

  describe "#call" do
    it "adds prompt to transcript and calls chat completion" do
      allow(Roast::Helpers::PromptLoader).to(receive(:load_prompt)
        .with(step, workflow.file)
        .and_return("Test prompt"))

      allow(workflow).to(receive(:chat_completion)
        .and_return("Test chat completion response"))

      result = step.call
      expect(workflow.transcript.last).to(eq({ user: "Test prompt" }))
      expect(result).to(eq("Test chat completion response"))
    end
  end
end
