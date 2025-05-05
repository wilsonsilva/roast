# frozen_string_literal: true

require "spec_helper"
require "roast/workflow/base_workflow"

RSpec.describe(Roast::Workflow::BaseWorkflow) do
  let(:file) { test_fixture_file("test.rb") }

  describe "#initialize" do
    before do
      allow(Roast::Helpers::PromptLoader).to(receive(:load_prompt)
        .and_return("Test prompt"))
      allow(Roast::Tools).to(receive(:setup_interrupt_handler))
    end

    it "initializes with file and sets up transcript" do
      workflow = described_class.new(file)

      expect(workflow.file).to(eq(file))
      expect(workflow.transcript).to(eq([{ system: "Test prompt" }]))
      expect(Roast::Tools).to(have_received(:setup_interrupt_handler))
    end
  end

  describe "#append_to_final_output and #final_output" do
    let(:workflow) { described_class.new(file) }

    it "appends to final output and returns it" do
      workflow.append_to_final_output("Test output")
      expect(workflow.final_output).to(eq("Test output"))
    end
  end
end
