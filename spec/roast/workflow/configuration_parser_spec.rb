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

    context "with instrumentation" do
      let(:test_file) { test_fixture_file("test.rb") }
      let(:parser) { described_class.new(workflow_path, [test_file]) }
      let(:events) { [] }

      before do
        ActiveSupport::Notifications.subscribe(/roast\./) do |name, _start, _finish, _id, payload|
          events << { name: name, payload: payload }
        end

        # Stub the workflow execution to avoid actual execution
        executor = instance_double(Roast::Workflow::WorkflowExecutor)
        allow(Roast::Workflow::WorkflowExecutor).to(receive(:new).and_return(executor))
        allow(executor).to(receive(:execute_steps))
      end

      after do
        ActiveSupport::Notifications.unsubscribe(/roast\./)
      end

      it "instruments workflow start and complete events" do
        parser.begin!

        start_event = events.find { |e| e[:name] == "roast.workflow.start" }
        complete_event = events.find { |e| e[:name] == "roast.workflow.complete" }

        expect(start_event).not_to(be_nil)
        expect(start_event[:payload][:workflow_path]).to(eq(workflow_path))

        expect(complete_event).not_to(be_nil)
        expect(complete_event[:payload][:success]).to(be(true))
        expect(complete_event[:payload][:execution_time]).to(be_a(Float))
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
