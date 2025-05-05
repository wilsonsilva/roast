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
    context "with % prefix" do
      it "executes shell command" do
        expect(executor).to(receive(:strip_and_execute).with("%ls").and_return("file1\nfile2"))
        result = executor.execute_step("%ls")
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
