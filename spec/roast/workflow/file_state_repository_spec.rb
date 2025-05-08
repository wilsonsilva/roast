# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "json"

module Roast
  module Workflow
    RSpec.describe(FileStateRepository) do
      let(:temp_dir) { Dir.mktmpdir }
      let(:file) { File.join(temp_dir, "test.rb") }
      let(:session_name) { "test_workflow" }
      let(:session_manager) { SessionManager.new }
      let(:repository) { FileStateRepository.new(session_manager) }

      before do
        # Create test file and stub pwd
        FileUtils.touch(file)
        allow(Dir).to(receive(:pwd).and_return(temp_dir))

        # Create a mock workflow
        @workflow = instance_double(
          BaseWorkflow,
          file: file,
          session_name: session_name,
          session_timestamp: nil,
          object_id: 12345,
        )
        allow(@workflow).to(receive(:session_timestamp=))
      end

      after do
        FileUtils.remove_entry(temp_dir) if temp_dir && File.exist?(temp_dir)
      end

      describe "#save_state" do
        let(:state_data) do
          {
            step_name: "test_step",
            order: 1,
            transcript: [],
            output: {},
            final_output: [],
            execution_order: ["test_step"],
          }
        end

        it "creates directory structure and saves state" do
          repository.save_state(@workflow, "test_step", state_data)

          # Verify directory structure
          workflow_dir = expected_workflow_dir
          expect(File.directory?(workflow_dir)).to(be(true))
          expect(File.exist?(File.join(workflow_dir, ".gitignore"))).to(be(true))

          session_dirs = Dir.children(workflow_dir).reject { |f| f == ".gitignore" }
          expect(session_dirs.size).to(eq(1))

          session_dir = File.join(workflow_dir, session_dirs.first)
          state_files = Dir.glob(File.join(session_dir, "step_*_*.json"))
          expect(state_files.size).to(eq(1))

          # Verify file content
          state = JSON.parse(File.read(state_files.first))
          expect(state["step_name"]).to(eq("test_step"))
          expect(state["order"]).to(eq(1))
        end

        it "handles errors gracefully" do
          allow(File).to(receive(:write).and_raise(Errno::EACCES))

          expect { repository.save_state(@workflow, "test_step", state_data) }
            .to(output(/Failed to save state/).to_stderr)
        end
      end

      describe "#load_state_before_step" do
        it "returns false when no directory exists" do
          result = repository.load_state_before_step(@workflow, "test_step")
          expect(result).to(be(false))
        end

        it "returns false when no sessions exist" do
          FileUtils.mkdir_p(expected_workflow_dir)
          result = repository.load_state_before_step(@workflow, "test_step")
          expect(result).to(be(false))
        end

        it "returns false for the first step" do
          create_test_state("step1", 1)
          result = repository.load_state_before_step(@workflow, "step1")
          expect(result).to(be(false))
        end

        it "returns false when step not found" do
          create_test_state("step1", 1)
          result = repository.load_state_before_step(@workflow, "non_existent")
          expect(result).to(be(false))
        end

        it "loads previous state" do
          timestamp = Time.now.utc.strftime("%Y%m%d_%H%M%S_%L")

          # Set a specific session timestamp
          session_manager.set_session_timestamp(12345, timestamp)

          # Create a workflow with the specific timestamp
          workflow = instance_double(
            BaseWorkflow,
            file: file,
            session_name: session_name,
            session_timestamp: timestamp,
            object_id: 12345,
          )
          allow(workflow).to(receive(:session_timestamp=))

          # Create states in this session
          create_test_state_with_workflow(workflow, "step1", 1, user_data: "step1 data")
          create_test_state_with_workflow(workflow, "step2", 2, user_data: "step2 data")

          # Now load the state before step2, which should be step1
          result = repository.load_state_before_step(workflow, "step2")
          expect(result).to(be_truthy)
          expect(result[:step_name]).to(eq("step1"))
          expect(result[:user_data]).to(eq("step1 data"))
        end
      end

      describe "#save_final_output" do
        it "creates a file with the output content" do
          result = repository.save_final_output(@workflow, "Final output content")

          expect(result).to(be_truthy)
          expect(File.exist?(result)).to(be(true))
          expect(File.read(result)).to(eq("Final output content"))
          expect(result).to(match(/final_output\.txt$/))
        end

        it "returns nil for empty content" do
          result = repository.save_final_output(@workflow, "")
          expect(result).to(be_nil)
        end

        it "handles errors gracefully" do
          allow(File).to(receive(:write).and_raise(Errno::EACCES))

          expect { repository.save_final_output(@workflow, "content") }
            .to(output(/Failed to save final output/).to_stderr)
        end
      end

      private

      def expected_workflow_dir
        workflow_dir_name = @workflow.session_name.parameterize.underscore
        file_id = Digest::MD5.hexdigest(@workflow.file)
        file_basename = File.basename(@workflow.file).parameterize.underscore
        human_readable_id = "#{file_basename}_#{file_id[0..7]}"
        File.join(temp_dir, ".roast", "sessions", workflow_dir_name, human_readable_id)
      end

      def create_test_state(step_name, order, additional_data = {})
        state_data = {
          step_name: step_name,
          order: order,
          transcript: [],
          output: {},
          final_output: [],
          execution_order: [step_name],
        }.merge(additional_data)

        repository.save_state(@workflow, step_name, state_data)
      end

      def create_test_state_with_workflow(workflow, step_name, order, additional_data = {})
        state_data = {
          step_name: step_name,
          order: order,
          transcript: [],
          output: {},
          final_output: [],
          execution_order: [step_name],
        }.merge(additional_data)

        repository.save_state(workflow, step_name, state_data)
      end
    end
  end
end
