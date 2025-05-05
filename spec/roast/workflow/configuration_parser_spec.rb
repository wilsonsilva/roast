# frozen_string_literal: true

require "spec_helper"
require "roast/workflow/configuration_parser"

RSpec.describe(Roast::Workflow::ConfigurationParser) do
  let(:workflow_path) { test_fixture_file("workflow/workflow.yml") }
  let(:parser) { described_class.new(workflow_path) }

  describe "#initialize" do
    it "initializes with the example workflow" do
      expect(parser.configuration).to(be_a(Roast::Workflow::Configuration))
      expect(parser.configuration.steps.first).to(eq("run_coverage"))
    end
  end

  describe "#begin!" do
    context "without files or target" do
      it "outputs error message when no files or target provided" do
        expect { parser.begin! }.to(output(/ERROR: No files or target provided!/).to_stdout)
      end
    end

    context "with files" do
      let(:test_file) { test_fixture_file("test.rb") }
      let(:parser) { described_class.new(workflow_path, [test_file]) }

      it "initializes workflow for each file" do
        # We'll stub the execution to avoid errors from missing dependencies
        executor = instance_double(Roast::Workflow::WorkflowExecutor)
        allow(Roast::Workflow::WorkflowExecutor).to(receive(:new).and_return(executor))
        allow(executor).to(receive(:execute_steps))

        # Verify it tries to set up workflow for each file
        expect { parser.begin! }.to(output(/Running workflow for file: #{test_file}/).to_stderr)
        expect(Roast::Workflow::WorkflowExecutor).to(have_received(:new))
      end
    end
  end
end
