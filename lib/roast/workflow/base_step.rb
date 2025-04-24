# frozen_string_literal: true

require "erb"
require "forwardable"

module Roast
  module Workflow
    class BaseStep
      extend Forwardable

      attr_accessor :model, :print_response, :loop, :json, :params
      attr_reader :workflow, :name, :context_path

      def_delegator :workflow, :append_to_final_output
      def_delegator :workflow, :chat_completion
      def_delegator :workflow, :transcript

      def initialize(workflow, model: "anthropic:claude-3-7-sonnet", name: nil, context_path: nil)
        @workflow = workflow
        @model = model
        @name = name || self.class.name.underscore.split("/").last
        @context_path = context_path || determine_context_path
        @print_response = false
        @loop = true
        @json = false
        @params = {}
      end

      def call
        prompt(read_sidecar_prompt)
        chat_completion(print_response:, loop:, json:, params:)
      end

      protected

      def chat_completion(print_response: false, loop: true, json: false, params: {})
        workflow.chat_completion(openai: model, loop:, json:, params:).tap do |response|
          append_to_final_output(response) if print_response
        end.then do |response|
          case response
          in Array
            response.map(&:presence).compact.join("\n")
          else
            response
          end
        end.tap do |response|
          process_sidecar_output(response)
        end
      end

      # Determine the directory where the actual class is defined, not BaseWorkflow
      def determine_context_path
        # Get the actual class's source file
        klass = self.class

        # Try to get the file path where the class is defined
        path = if klass.name.include?("::")
          # For namespaced classes like Roast::Workflow::Grading::Workflow
          # Convert the class name to a relative path
          class_path = klass.name.underscore + ".rb"
          # Look through load path to find the actual file
          $LOAD_PATH.map { |p| File.join(p, class_path) }.find { |f| File.exist?(f) }
        else
          # Fall back to the current file if we can't find it
          __FILE__
        end

        # Return directory containing the class definition
        File.dirname(path || __FILE__)
      end

      def prompt(text)
        transcript << { user: text }
      end

      def read_sidecar_prompt
        Roast::Helpers::PromptLoader.load_prompt(self, workflow.file)
      end

      def process_sidecar_output(response)
        # look for a file named output.txt.erb in the context path
        # if found, render it with the response
        # if not found, just return the response
        # TODO: this can be a lot more sophisticated
        # incorporating different file types, etc.
        output_path = File.join(context_path, "output.txt")
        if File.exist?(output_path)
          # TODO: use the workflow binding or the step?
          append_to_final_output(ERB.new(File.read(output_path), trim_mode: "-").result(binding))
        end
      end
    end
  end
end
