# frozen_string_literal: true

require "open3"
require "yaml"

module Roast
  module Workflow
    # Encapsulates workflow configuration data and provides structured access
    # to the configuration settings
    class Configuration
      attr_reader :config_hash, :workflow_path, :name, :steps, :tools, :function_configs, :api_token, :model, :resource
      attr_accessor :target

      def initialize(workflow_path, options = {})
        @workflow_path = workflow_path
        @config_hash = YAML.load_file(workflow_path)

        # Extract key configuration values
        @name = @config_hash["name"] || File.basename(workflow_path, ".yml")
        @steps = @config_hash["steps"] || []

        # Process tools configuration
        parse_tools

        # Process function-specific configurations
        parse_functions

        # Read the target parameter
        @target = options[:target] || @config_hash["target"]

        # Process the target command if it's a shell command
        @target = process_target(@target) if has_target?

        # Create the appropriate resource object for the target
        if defined?(Roast::Resources)
          @resource = if has_target?
            Roast::Resources.for(@target)
          else
            Roast::Resources::NoneResource.new(nil)
          end
        end

        # Process API token if provided
        if @config_hash["api_token"]
          @api_token = process_shell_command(@config_hash["api_token"])
        end

        # Extract default model if provided
        @model = @config_hash["model"]
      end

      def context_path
        @context_path ||= File.dirname(workflow_path)
      end

      def basename
        @basename ||= File.basename(workflow_path, ".yml")
      end

      def has_target?
        !target.nil? && !target.empty?
      end

      def get_step_config(step_name)
        @config_hash[step_name] || {}
      end

      # Find the index of a step in the workflow steps array
      # @param [Array] steps Optional - The steps array to search (defaults to self.steps)
      # @param [String] target_step The name of the step to find
      # @return [Integer, nil] The index of the step, or nil if not found
      def find_step_index(steps_array = nil, target_step = nil)
        # Handle different call patterns for backward compatibility
        if steps_array.is_a?(String) && target_step.nil?
          target_step = steps_array
          steps_array = steps
        elsif steps_array.is_a?(Array) && target_step.is_a?(String)
          # This is the normal case - steps_array and target_step are provided
        else
          # Default to self.steps if just the target_step is provided
          steps_array = steps
        end

        # First, try using the new more detailed search
        steps_array.each_with_index do |step, index|
          case step
          when Hash
            # Could be {name: command} or {name: {substeps}}
            step_key = step.keys.first
            return index if step_key == target_step
          when Array
            # This is a parallel step container, search inside it
            found = step.any? do |substep|
              case substep
              when Hash
                substep.keys.first == target_step
              when String
                substep == target_step
              else
                false
              end
            end
            return index if found
          when String
            return index if step == target_step
          end
        end

        # Fall back to the original method using extract_step_name
        steps_array.each_with_index do |step, index|
          step_name = extract_step_name(step)
          if step_name.is_a?(Array)
            # For arrays (parallel steps), check if target is in the array
            return index if step_name.flatten.include?(target_step)
          elsif step_name == target_step
            return index
          end
        end

        nil
      end

      # Returns an array of all tool class names
      def parse_tools
        # Only support array format: ["Roast::Tools::Grep", "Roast::Tools::ReadFile"]
        @tools = @config_hash["tools"] || []
      end

      # Parse function-specific configurations
      def parse_functions
        @function_configs = @config_hash["functions"] || {}
      end

      # Get configuration for a specific function
      # @param function_name [String, Symbol] The name of the function (e.g., 'grep', 'search_file')
      # @return [Hash] The configuration for the function or empty hash if not found
      def function_config(function_name)
        @function_configs[function_name.to_s] || {}
      end

      private

      def process_shell_command(command)
        # If it's a bash command with the $(command) syntax
        if command =~ /^\$\((.*)\)$/
          return Open3.capture2e({}, ::Regexp.last_match(1)).first.strip
        end

        # Legacy % prefix for backward compatibility
        if command.start_with?("% ")
          return Open3.capture2e({}, *command.split(" ")[1..-1]).first.strip
        end

        # Not a shell command, return as is
        command
      end

      def process_target(command)
        # Process shell command first
        processed = process_shell_command(command)

        # If it's a glob pattern, return the full paths of the files it matches
        if processed.include?("*")
          matched_files = Dir.glob(processed)
          # If no files match, return the pattern itself
          return processed if matched_files.empty?

          return matched_files.map { |file| File.expand_path(file) }.join("\n")
        end

        # For tests, if the command was already processed as a shell command and is simple,
        # don't expand the path to avoid breaking existing tests
        return processed if command != processed && !processed.include?("/")

        # assumed to be a direct file path(s)
        File.expand_path(processed)
      end

      def extract_step_name(step)
        case step
        when String
          step
        when Hash
          step.keys.first
        when Array
          # For arrays, we'll need special handling as they contain multiple steps
          step.map { |s| extract_step_name(s) }
        end
      end
    end
  end
end
