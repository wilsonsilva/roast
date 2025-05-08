# frozen_string_literal: true

require "spec_helper"
require "roast/workflow/workflow_executor"

RSpec.describe(Roast::Workflow::WorkflowExecutor) do
  let(:workflow) { double("workflow", output: {}) }
  let(:config_hash) { { "step1" => { "model" => "test-model" } } }
  let(:context_path) { "/tmp/test" }
  let(:executor) { described_class.new(workflow, config_hash, context_path) }

  describe "#execute_steps" do
    context "with string steps" do
      it "executes string steps" do
        expect(executor).to(receive(:execute_step).with("step1"))
        executor.execute_steps(["step1"])
      end
    end

    context "with hash steps" do
      it "executes hash steps" do
        expect(workflow).to(receive(:output))
        expect(executor).to(receive(:execute_step).with("command1").and_return("result"))
        executor.execute_steps([{ "var1" => "command1" }])
      end
    end

    context "with array steps (parallel execution)" do
      it "executes steps in parallel" do
        expect(Thread).to(receive(:new).twice) do ||
          double.tap { |thread| expect(thread).to(receive(:join)) }
        end

        executor.execute_steps([["step1", "step2"]])
      end
    end

    context "with unknown step type" do
      it "raises an error" do
        expect do
          executor.execute_steps([Object.new])
        end.to(raise_error(/Unknown step type/))
      end
    end
  end

  describe "#execute_step" do
    context "with instrumentation" do
      let(:events) { [] }

      before do
        ActiveSupport::Notifications.subscribe(/roast\.step\./) do |name, _start, _finish, _id, payload|
          events << { name: name, payload: payload }
        end
      end

      after do
        ActiveSupport::Notifications.unsubscribe(/roast\.step\./)
      end

      it "instruments step execution" do
        step_obj = double("step")
        allow(step_obj).to(receive(:call).and_return("result"))
        allow(executor).to(receive(:find_and_load_step).and_return(step_obj))

        executor.execute_step("test_step")

        start_event = events.find { |e| e[:name] == "roast.step.start" }
        complete_event = events.find { |e| e[:name] == "roast.step.complete" }

        expect(start_event).not_to(be_nil)
        expect(start_event[:payload][:step_name]).to(eq("test_step"))

        expect(complete_event).not_to(be_nil)
        expect(complete_event[:payload][:step_name]).to(eq("test_step"))
        expect(complete_event[:payload][:success]).to(be(true))
        expect(complete_event[:payload][:execution_time]).to(be_a(Float))
        expect(complete_event[:payload][:result_size]).to(be_a(Integer))
      end

      it "instruments step errors" do
        allow(executor).to(receive(:find_and_load_step)).and_raise(StandardError.new("test error"))

        expect { executor.execute_step("failing_step") }.to(raise_error(StandardError))

        error_event = events.find { |e| e[:name] == "roast.step.error" }

        expect(error_event).not_to(be_nil)
        expect(error_event[:payload][:step_name]).to(eq("failing_step"))
        expect(error_event[:payload][:error]).to(eq("StandardError"))
        expect(error_event[:payload][:message]).to(eq("test error"))
        expect(error_event[:payload][:execution_time]).to(be_a(Float))
      end
    end

    context "with $(bash expression)" do
      it "executes shell command" do
        expect(executor).to(receive(:strip_and_execute).with("$(ls)").and_return("file1\nfile2"))
        expect(workflow).to(receive(:transcript).and_return([]))
        expect(workflow).to(receive(:transcript).and_return([]))
        result = executor.execute_step("$(ls)")
        expect(result).to(eq("file1\nfile2"))
      end
    end

    context "with glob pattern" do
      it "expands glob pattern" do
        expect(executor).to(receive(:glob).with("*.rb").and_return("file1.rb\nfile2.rb"))
        result = executor.execute_step("*.rb")
        expect(result).to(eq("file1.rb\nfile2.rb"))
      end
    end

    context "with regular step" do
      let(:step_object) { double("step", call: "result") }

      before do
        allow(executor).to(receive(:find_and_load_step).and_return(step_object))
      end

      it "loads and executes step object" do
        expect(step_object).to(receive(:call).and_return("result"))
        expect(workflow.output).to(receive(:[]=).with("step1", "result"))

        result = executor.execute_step("step1")
        expect(result).to(eq("result"))
      end
    end
  end
end
