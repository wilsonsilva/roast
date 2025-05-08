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
      it "runs as a targetless workflow" do
        # Mock the setup and execution to avoid ERB errors
        executor = instance_double(Roast::Workflow::WorkflowExecutor)
        allow(Roast::Workflow::WorkflowExecutor).to(receive(:new).and_return(executor))
        allow(executor).to(receive(:execute_steps))

        # Allow proper setup of the workflow
        workflow = instance_double(
          Roast::Workflow::BaseWorkflow,
          output: {},
          final_output: "",
          output_file: nil,
        )
        allow(Roast::Workflow::BaseWorkflow).to(receive(:new).and_return(workflow))
        allow(workflow).to(receive(:output_file=))
        allow(workflow).to(receive(:verbose=))

        expect { parser.begin! }.to(output(/Running targetless workflow/).to_stderr)
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

  describe "#find_step_index_in_array" do
    let(:steps) { ["step1", { "var1" => "step2" }, ["step3", "step4"]] }

    it "finds index of simple string steps" do
      expect(parser.send(:find_step_index_in_array, steps, "step1")).to(eq(0))
    end

    it "finds index of hash steps" do
      expect(parser.send(:find_step_index_in_array, steps, "var1")).to(eq(1))
    end

    it "finds index within parallel steps" do
      expect(parser.send(:find_step_index_in_array, steps, "step3")).to(eq(2))
      expect(parser.send(:find_step_index_in_array, steps, "step4")).to(eq(2))
    end

    it "returns nil for non-existent steps" do
      expect(parser.send(:find_step_index_in_array, steps, "nonexistent")).to(be_nil)
    end
  end

  describe "#load_state_and_update_steps" do
    let(:steps) { ["step1", "step2", "step3", "step4"] }
    let(:workflow) { instance_double(Roast::Workflow::BaseWorkflow) }
    let(:state_repository) { instance_double(Roast::Workflow::FileStateRepository) }

    before do
      allow(parser).to(receive(:current_workflow).and_return(workflow))
      allow(Roast::Workflow::FileStateRepository).to(receive(:new).and_return(state_repository))
    end

    it "returns steps from the requested index when state loading fails" do
      allow(state_repository).to(receive(:load_state_before_step).and_return(false))

      result = parser.send(:load_state_and_update_steps, steps, 2, "step3", nil)

      expect(result).to(eq(["step3", "step4"]))
      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step3"))
    end

    it "returns steps from the requested index when state loading succeeds" do
      allow(state_repository).to(receive(:load_state_before_step).and_return({ step_name: "step2" }))

      result = parser.send(:load_state_and_update_steps, steps, 2, "step3", nil)

      expect(result).to(eq(["step3", "step4"]))
      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step3"))
    end

    it "returns steps from the requested index when loading from timestamp fails" do
      timestamp = "20230101_000000_000"
      allow(state_repository).to(receive(:load_state_before_step).and_return(false))

      result = parser.send(:load_state_and_update_steps, steps, 1, "step2", timestamp)

      expect(result).to(eq(["step2", "step3", "step4"]))
      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step2", hash_including(timestamp: timestamp)))
    end
  end

  describe "#parse with replay option" do
    let(:steps) { ["step1", "step2", "step3", "step4"] }
    let(:workflow) { instance_double(Roast::Workflow::BaseWorkflow, output_file: nil, final_output: "") }
    let(:state_repository) { instance_double(Roast::Workflow::FileStateRepository) }
    let(:executor) { instance_double(Roast::Workflow::WorkflowExecutor) }

    before do
      allow(parser).to(receive(:current_workflow).and_return(workflow))
      allow(Roast::Workflow::FileStateRepository).to(receive(:new).and_return(state_repository))
      allow(Roast::Workflow::WorkflowExecutor).to(receive(:new).and_return(executor))
      allow(executor).to(receive(:execute_steps))
      allow(parser).to(receive(:save_final_output))
      # Use the real find_step_index_in_array method
    end

    it "starts execution from the specified step when no state exists" do
      parser.instance_variable_set(:@options, { replay: "step3" })
      allow(state_repository).to(receive(:load_state_before_step).and_return(false))

      expect(executor).to(receive(:execute_steps).with(["step3", "step4"]))

      parser.send(:parse, steps)

      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step3"))
    end

    it "starts execution from the specified step when state exists" do
      parser.instance_variable_set(:@options, { replay: "step2" })
      allow(state_repository).to(receive(:load_state_before_step).and_return({ step_name: "step1" }))

      expect(executor).to(receive(:execute_steps).with(["step2", "step3", "step4"]))

      parser.send(:parse, steps)

      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step2"))
    end

    it "handles timestamp in replay parameter" do
      timestamp = "20230101_000000_000"
      parser.instance_variable_set(:@options, { replay: "#{timestamp}:step3" })
      allow(state_repository).to(receive(:load_state_before_step).and_return(false))
      allow(workflow).to(receive(:session_timestamp=))

      expect(executor).to(receive(:execute_steps).with(["step3", "step4"]))

      parser.send(:parse, steps)

      expect(workflow).to(have_received(:session_timestamp=).with(timestamp))
      expect(state_repository).to(have_received(:load_state_before_step).with(workflow, "step3", hash_including(timestamp: timestamp)))
    end

    it "runs all steps when specified step is not found" do
      parser.instance_variable_set(:@options, { replay: "nonexistent_step" })

      expect(executor).to(receive(:execute_steps).with(steps))

      expect { parser.send(:parse, steps) }.to(output(/Step nonexistent_step not found/).to_stderr)
    end
  end
end
