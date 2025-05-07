# frozen_string_literal: true

require "active_support"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module Roast
  module Workflow
    # Handles the execution of workflow steps, including orchestration and threading
    class WorkflowExecutor
      DEFAULT_MODEL = "anthropic:claude-3-7-sonnet"

      attr_reader :workflow, :config_hash, :context_path

      def initialize(workflow, config_hash, context_path)
        @workflow = workflow
        @config_hash = config_hash
        @context_path = context_path
      end

      def execute_steps(steps)
        steps.each do |step|
          case step
          when Hash
            execute_hash_step(step)
          when Array
            execute_parallel_steps(step)
          when String
            execute_string_step(step)
          else
            raise "Unknown step type: #{step.inspect}"
          end
        end
      end

      def execute_step(name)
        start_time = Time.now
        # For tests, make sure that we handle this gracefully
        resource_type = workflow.respond_to?(:resource) ? workflow.resource&.type : nil

        ActiveSupport::Notifications.instrument("roast.step.start", {
          step_name: name,
          resource_type: resource_type,
        })

        $stderr.puts "Executing: #{name} (Resource type: #{resource_type || "unknown"})"

        result = if name.starts_with?("%") || name.starts_with?("$(")
          strip_and_execute(name)
        elsif name.include?("*") && (!workflow.respond_to?(:resource) || !workflow.resource)
          # Only use the glob method if we don't have a resource object yet
          # This is for backward compatibility
          glob(name)
        else
          step_object = find_and_load_step(name)
          step_result = step_object.call
          workflow.output[name] = step_result
          step_result
        end

        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.step.complete", {
          step_name: name,
          resource_type: resource_type,
          success: true,
          execution_time: execution_time,
          result_size: result.to_s.length,
        })

        result
      rescue => e
        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.step.error", {
          step_name: name,
          resource_type: resource_type,
          error: e.class.name,
          message: e.message,
          execution_time: execution_time,
        })
        raise
      end

      private

      def execute_hash_step(step)
        # execute a command and store the output in a variable
        name, command = step.to_a.flatten
        if command.is_a?(Hash)
          execute_steps([command])
        else
          workflow.output[name] = execute_step(command)
        end
      end

      def execute_parallel_steps(steps)
        # run steps in parallel, don't proceed until all are done
        steps.map do |sub_step|
          Thread.new { execute_steps([sub_step]) }
        end.each(&:join)
      end

      def execute_string_step(step)
        execute_step(step)
      end

      def find_and_load_step(step_name)
        # First check for a ruby file with the step name
        rb_file_path = File.join(context_path, "#{step_name}.rb")
        if File.file?(rb_file_path)
          return load_ruby_step(rb_file_path, step_name)
        end

        # Check in shared directory for ruby file
        shared_rb_path = File.expand_path(File.join(context_path, "..", "shared", "#{step_name}.rb"))
        if File.file?(shared_rb_path)
          return load_ruby_step(shared_rb_path, step_name, File.dirname(shared_rb_path))
        end

        # Continue with existing directory check logic
        step_path = File.join(context_path, step_name)
        step_path = File.expand_path(File.join(context_path, "..", "shared", step_name)) unless File.directory?(step_path)
        raise "Step directory or file not found: #{step_path}" unless File.directory?(step_path)

        setup_step(Roast::Workflow::BaseStep, step_name, step_path)
      end

      def glob(name)
        Dir.glob(name).join("\n")
      end

      def load_ruby_step(file_path, step_name, context_path = File.dirname(file_path))
        $stderr.puts "Requiring step file: #{file_path}"
        require file_path
        step_class = step_name.classify.constantize
        setup_step(step_class, step_name, context_path)
      end

      def setup_step(step_class, step_name, context_path)
        step_class.new(workflow, name: step_name, context_path: context_path).tap do |step|
          step_config = config_hash[step_name]

          # Always set the model, even if there's no step_config
          # Use step-specific model if defined, otherwise use workflow default model, or fallback to DEFAULT_MODEL
          step.model = step_config&.dig("model") || config_hash["model"] || DEFAULT_MODEL

          # Pass resource to step if supported
          step.resource = workflow.resource if step.respond_to?(:resource=)

          if step_config.present?
            step.print_response = step_config["print_response"] if step_config["print_response"].present?
            step.loop = step_config["loop"] if step_config["loop"].present?
            step.json = step_config["json"] if step_config["json"].present?
            step.params = step_config["params"] if step_config["params"].present?
          end
        end
      end

      def strip_and_execute(step)
        command = step.gsub("%", "")
        %x(#{command})
      end
    end
  end
end
