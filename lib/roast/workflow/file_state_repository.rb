# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "session_manager"
require_relative "state_repository"

module Roast
  module Workflow
    # File-based implementation of StateRepository
    # Handles state persistence to the filesystem in a thread-safe manner
    class FileStateRepository < StateRepository
      def initialize(session_manager = SessionManager.new)
        super()
        @state_mutex = Mutex.new
        @session_manager = session_manager
      end

      def save_state(workflow, step_name, state_data)
        @state_mutex.synchronize do
          # If workflow doesn't have a timestamp, let the session manager create one
          workflow.session_timestamp ||= @session_manager.create_new_session(workflow.object_id)

          session_dir = @session_manager.ensure_session_directory(
            workflow.object_id,
            workflow.session_name,
            workflow.file,
            timestamp: workflow.session_timestamp,
          )
          step_file = File.join(session_dir, format_step_filename(state_data[:order], step_name))
          File.write(step_file, JSON.pretty_generate(state_data))
        end
      rescue => e
        $stderr.puts "Failed to save state for step #{step_name}: #{e.message}"
      end

      def load_state_before_step(workflow, step_name, timestamp: nil)
        session_dir = @session_manager.find_session_directory(workflow.session_name, workflow.file, timestamp)
        return false unless session_dir

        step_files = find_step_files(session_dir)
        target_index = find_step_before(step_files, step_name)
        return false if target_index.nil? || target_index < 0

        state_data = load_state_file(step_files[target_index])

        # If no timestamp provided and workflow has no session, copy states to new session
        should_copy = !timestamp && workflow.session_timestamp.nil?

        copy_states_to_new_session(workflow, session_dir, step_files[0..target_index]) if should_copy
        state_data
      end

      def save_final_output(workflow, output_content)
        return if output_content.empty?

        session_dir = @session_manager.ensure_session_directory(
          workflow.object_id,
          workflow.session_name,
          workflow.file,
          timestamp: workflow.session_timestamp,
        )
        output_file = File.join(session_dir, "final_output.txt")
        File.write(output_file, output_content)
        $stderr.puts "Final output saved to: #{output_file}"
        output_file
      rescue => e
        $stderr.puts "Failed to save final output: #{e.message}"
        nil
      end

      private

      def find_step_files(session_dir)
        Dir.glob(File.join(session_dir, "step_*_*.json")).sort_by do |file|
          file[/step_(\d+)_/, 1].to_i
        end
      end

      def find_step_before(step_files, target_step_name)
        step_files.each_with_index do |file, index|
          if file.end_with?("_#{target_step_name}.json")
            return index - 1
          end
        end
        nil
      end

      def load_state_file(state_file)
        JSON.parse(File.read(state_file), symbolize_names: true)
      end

      def copy_states_to_new_session(workflow, source_session_dir, state_files)
        # Create a new session for the workflow
        new_timestamp = @session_manager.create_new_session(workflow.object_id)
        workflow.session_timestamp = new_timestamp

        # Get the new session directory path
        current_session_dir = @session_manager.ensure_session_directory(
          workflow.object_id,
          workflow.session_name,
          workflow.file,
          timestamp: workflow.session_timestamp,
        )

        # Skip copying if the source and destination are the same
        return if source_session_dir == current_session_dir

        # Make sure the new directory actually exists before copying
        FileUtils.mkdir_p(current_session_dir) unless File.directory?(current_session_dir)

        # Copy each state file to the new session directory
        state_files.each do |state_file|
          FileUtils.cp(state_file, current_session_dir)
        end

        # Return success
        true
      end

      def format_step_filename(order, step_name)
        "step_#{order.to_s.rjust(3, "0")}_#{step_name}.json"
      end
    end
  end
end
