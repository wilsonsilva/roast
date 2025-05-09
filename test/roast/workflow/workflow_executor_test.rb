# frozen_string_literal: true

require "test_helper"
require "roast/workflow/workflow_executor"

class RoastWorkflowWorkflowExecutorTest < ActiveSupport::TestCase
  def setup
    @workflow = mock("workflow")
    @output = {}
    @workflow.stubs(output: @output)
    @config_hash = { "step1" => { "model" => "test-model" } }
    @context_path = "/tmp/test"
    @executor = Roast::Workflow::WorkflowExecutor.new(@workflow, @config_hash, @context_path)
  end

  # String steps tests
  test "executes string steps" do
    @executor.expects(:execute_step).with("step1")
    @executor.execute_steps(["step1"])
  end

  # Hash steps tests
  test "executes hash steps" do
    @executor.expects(:execute_step).with("command1").returns("result")
    @executor.execute_steps([{ "var1" => "command1" }])
    assert_equal "result", @output["var1"]
  end

  # Array steps (parallel execution) tests
  test "executes steps in parallel" do
    mock_thread = mock
    mock_thread.expects(:join).twice
    Thread.expects(:new).twice.returns(mock_thread)

    @executor.execute_steps([["step1", "step2"]])
  end

  # Unknown step type tests
  test "raises an error for unknown step type" do
    assert_raises(RuntimeError) do
      @executor.execute_steps([Object.new])
    end
  end

  # Instrumentation tests
  test "instruments step execution" do
    events = []

    subscription = ActiveSupport::Notifications.subscribe(/roast\.step\./) do |name, _start, _finish, _id, payload|
      events << { name: name, payload: payload }
    end

    step_obj = mock("step")
    step_obj.expects(:call).returns("result")
    @executor.expects(:find_and_load_step).returns(step_obj)

    @executor.execute_step("test_step")

    start_event = events.find { |e| e[:name] == "roast.step.start" }
    complete_event = events.find { |e| e[:name] == "roast.step.complete" }

    refute_nil start_event
    assert_equal "test_step", start_event[:payload][:step_name]

    refute_nil complete_event
    assert_equal "test_step", complete_event[:payload][:step_name]
    assert complete_event[:payload][:success]
    assert_instance_of Float, complete_event[:payload][:execution_time]
    assert_instance_of Integer, complete_event[:payload][:result_size]

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  test "instruments step errors" do
    events = []

    subscription = ActiveSupport::Notifications.subscribe(/roast\.step\./) do |name, _start, _finish, _id, payload|
      events << { name: name, payload: payload }
    end

    @executor.expects(:find_and_load_step).raises(StandardError.new("test error"))

    assert_raises(StandardError) do
      @executor.execute_step("failing_step")
    end

    error_event = events.find { |e| e[:name] == "roast.step.error" }

    refute_nil error_event
    assert_equal "failing_step", error_event[:payload][:step_name]
    assert_equal "StandardError", error_event[:payload][:error]
    assert_equal "test error", error_event[:payload][:message]
    assert_instance_of Float, error_event[:payload][:execution_time]

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  # Bash expression tests
  test "executes shell command for bash expression" do
    @executor.expects(:strip_and_execute).with("$(ls)").returns("file1\nfile2")
    @workflow.expects(:transcript).returns([]).twice

    result = @executor.execute_step("$(ls)")
    assert_equal "file1\nfile2", result
  end

  # Glob pattern tests
  test "expands glob pattern" do
    @executor.expects(:glob).with("*.rb").returns("file1.rb\nfile2.rb")

    result = @executor.execute_step("*.rb")
    assert_equal "file1.rb\nfile2.rb", result
  end

  # Regular step tests
  test "loads and executes step object" do
    step_object = mock("step")
    step_object.expects(:call).returns("result")
    @executor.expects(:find_and_load_step).returns(step_object)
    @workflow.output.expects(:[]=).with("step1", "result")

    result = @executor.execute_step("step1")
    assert_equal "result", result
  end
end
