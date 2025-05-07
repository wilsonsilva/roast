# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe(Roast::Workflow::ConfigurationParser) do
  describe "targetless workflow" do
    let(:workflow_path) { fixture_file_path("targetless_workflow.yml") }
    let(:parser) { Roast::Workflow::ConfigurationParser.new(workflow_path) }

    context "with mocked execution" do
      before do
        # Stub the setup_workflow method to not require actual execution
        allow(parser).to(receive(:setup_workflow).and_return(double("workflow", output: {})))
        allow(parser).to(receive(:parse))
      end

      it "executes workflow without a target" do
        expect(parser).to(receive(:setup_workflow).with(nil, name: anything, context_path: anything))
        expect(parser).to(receive(:parse))

        parser.begin!
      end
    end

    context "with real BaseWorkflow" do
      let(:workflow) { instance_double(Roast::Workflow::BaseWorkflow, output: {}, final_output: "", output_file: nil) }

      before do
        allow(Roast::Workflow::BaseWorkflow).to(receive(:new).and_return(workflow))
        allow(workflow).to(receive(:output_file=))
        allow(workflow).to(receive(:verbose=))
        # Need to return the workflow instead of true from execute_steps
        allow_any_instance_of(Roast::Workflow::WorkflowExecutor).to(receive(:execute_steps).and_return(workflow))
      end

      it "initializes BaseWorkflow with nil file" do
        expect(Roast::Workflow::BaseWorkflow).to(receive(:new) do |file, options|
          expect(file).to(be_nil)
          expect(options[:name]).to(be_a(String))
          expect(options[:context_path]).to(be_a(String))
          # Resource will be present in the options
          expect(options[:resource]).to(be_a(Roast::Resources::NoneResource))
          workflow
        end)
        parser.begin!
      end
    end
  end
end
