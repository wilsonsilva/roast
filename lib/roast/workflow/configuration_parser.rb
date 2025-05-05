# frozen_string_literal: true

require_relative "workflow_executor"
require_relative "configuration"
require_relative "../helpers/function_caching_interceptor"

module Roast
  module Workflow
    class ConfigurationParser
      extend Forwardable

      attr_reader :configuration, :options, :files, :current_workflow

      def_delegator :current_workflow, :output

      def initialize(workflow_path, files = [], options = {})
        @configuration = Configuration.new(workflow_path, options)
        @options = options
        @files = files
        include_tools
      end

      def begin!
        $stderr.puts "Starting workflow..."
        $stderr.puts "Workflow: #{configuration.workflow_path}"
        $stderr.puts "Options: #{options}"

        name = configuration.basename
        context_path = configuration.context_path

        if files.any?
          $stderr.puts "WARNING: Ignoring target parameter because files were provided: #{configuration.target}" if configuration.has_target?
          files.each do |file|
            $stderr.puts "Running workflow for file: #{file}"
            setup_workflow(file.strip, name:, context_path:)
            parse(configuration.steps)
          end
        elsif configuration.has_target?
          configuration.target.lines.each do |file|
            $stderr.puts "Running workflow for file: #{file.strip}"
            setup_workflow(file.strip, name:, context_path:)
            parse(configuration.steps)
          end
        else
          $stdout.puts "🚫 ERROR: No files or target provided! 🚫"
        end
      end

      private

      def setup_workflow(file, name:, context_path:)
        @current_workflow = BaseWorkflow.new(file, name:, context_path:).tap do |workflow|
          workflow.output_file = options[:output] if options[:output].present?
          workflow.subject_file = options[:subject] if options[:subject].present?
          workflow.verbose = options[:verbose] if options[:verbose].present?
        end
      end

      def include_tools
        return unless configuration.tools.present?

        BaseWorkflow.include(Raix::FunctionDispatch)
        BaseWorkflow.include(Roast::Helpers::FunctionCachingInterceptor) # Add caching support
        BaseWorkflow.include(*configuration.tools.map(&:constantize))
      end

      def parse(steps)
        return run(steps) if steps.is_a?(String)

        # Use the WorkflowExecutor to execute the steps
        executor = WorkflowExecutor.new(current_workflow, configuration.config_hash, configuration.context_path)
        executor.execute_steps(steps)

        $stderr.puts "🔥🔥🔥 ROAST COMPLETE! 🔥🔥🔥"

        # Save results to file if specified
        if current_workflow.output_file
          File.write(current_workflow.output_file, current_workflow.final_output)
          $stdout.puts "Results saved to #{current_workflow.output_file}"
        else
          $stdout.puts current_workflow.final_output
        end
      end

      # Delegates to WorkflowExecutor
      def run(name)
        executor = WorkflowExecutor.new(current_workflow, configuration.config_hash, configuration.context_path)
        executor.execute_step(name)
      end
    end
  end
end
