# frozen_string_literal: true

module Roast
  module Workflow
    class ConfigurationParser
      extend Forwardable

      DEFAULT_MODEL = "anthropic:claude-3-7-sonnet"

      attr_reader :configuration, :options, :workflow_path, :files, :current_workflow

      def_delegator :current_workflow, :output

      def initialize(workflow_path, files: [], options: {})
        @workflow_path = workflow_path
        @validator = Validator.new(File.read(workflow_path))
        raise "Invalid workflow configuration: #{@validator.errors.join(", ")}" unless @validator.valid?

        @configuration = YAML.load_file(workflow_path)
        @options = options
        @files = files
        include_tools
      end

      def begin!
        load_configuration(parse: true)
      end

      def load_configuration(parse: false)
        $stderr.puts "Loading configuration from: #{workflow_path}"
        $stderr.puts "Options: #{options}"

        name = File.basename(workflow_path, ".yml")
        context_path = File.dirname(workflow_path)

        if configuration["each"].present?
          $stderr.puts "WARNING: Overriding files with each parameter: #{configuration["each"]}" unless files.empty?
          run(configuration["each"]).lines.each do |file|
            $stderr.puts "Running workflow for file: #{file.strip}"
            setup_workflow(file.strip, name:, context_path:)
            parse ? parse(configuration["steps"]) : break
          end
        else
          files.each do |file|
            $stderr.puts "Running workflow for file: #{file}"
            setup_workflow(file.strip, name:, context_path:)
            parse ? parse(configuration["steps"]) : break
          end
        end
        @current_workflow
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
        return unless configuration["tools"].present?

        BaseWorkflow.include(Raix::FunctionDispatch)
        BaseWorkflow.include(*configuration["tools"].map(&:constantize))
      end

      def parse(steps)
        return run(steps) if steps.is_a?(String)

        steps.each do |step|
          if step.is_a?(Hash)
            # execute a command and store the output in a variable
            name, command = step.to_a.flatten
            if command.is_a?(Hash)
              parse(command)
            else
              output[name] = run(command)
            end
          elsif step.is_a?(Array)
            # run steps in parallel, don't proceed until all are done
            step.map do |sub_step|
              Thread.new { parse(sub_step) }
            end.each(&:join)
          elsif step.is_a?(String)
            run(step)
          else
            raise "Unknown step type: #{step.inspect}"
          end
        end

        $stderr.puts "🔥🔥🔥 ROAST COMPLETE! 🔥🔥🔥"
        # Save results to file if specified
        if current_workflow.output_file
          File.write(current_workflow.output_file, current_workflow.final_output)
          $stdout.puts "Results saved to #{current_workflow.output_file}"
        else
          $stdout.puts current_workflow.final_output
        end
      end

      # TODO: This method feels like could be implemented more cleanly
      # by moving step object creation into a new subclass
      # that knows how to load itself based on the name and context path
      def run(step_name)
        $stderr.puts "Running step: #{step_name}"
        return strip_and_execute(step_name) if step_name.starts_with?("%")

        # First check for a ruby file with the step name
        rb_file_path = File.join(File.dirname(workflow_path), "#{step_name}.rb")
        if File.file?(rb_file_path)
          $stderr.puts "Requiring step file: #{rb_file_path}"
          require rb_file_path
          step_object = setup(step_name.classify.constantize, name: step_name, context_path: File.dirname(rb_file_path))
          return output[step_name] = step_object.call
        end

        # Check in shared directory for ruby file
        shared_rb_path = File.expand_path(File.join(File.dirname(workflow_path), "..", "shared", "#{step_name}.rb"))
        if File.file?(shared_rb_path)
          $stderr.puts "Requiring shared step file: #{shared_rb_path}"
          require shared_rb_path
          step_object = setup(step_name.classify.constantize, name: step_name, context_path: File.dirname(shared_rb_path))
          return output[step_name] = step_object.call
        end

        # Continue with existing directory check logic
        step_path = File.join(File.dirname(workflow_path), step_name)
        step_path = File.expand_path(File.join(File.dirname(workflow_path), "..", "shared", step_name)) unless File.directory?(step_path)
        raise "Step directory or file not found: #{step_path}" unless File.directory?(step_path)

        step_object = setup(Roast::Workflow::BaseStep, name: step_name, context_path: step_path)
        output[step_name] = step_object.call
      end

      def setup(step_class, name:, context_path:)
        step_class.new(current_workflow, name:, context_path:).tap do |step|
          if configuration[name].present?
            step.model = configuration[name]["model"] || DEFAULT_MODEL
            step.print_response = configuration[name]["print_response"] if configuration[name]["print_response"].present?
            step.loop = configuration[name]["loop"] if configuration[name]["loop"].present?
            step.json = configuration[name]["json"] if configuration[name]["json"].present?
            step.params = configuration[name]["params"] if configuration[name]["params"].present?
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
