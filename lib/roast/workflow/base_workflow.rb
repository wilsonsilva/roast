# frozen_string_literal: true

require "raix/chat_completion"
require "raix/function_dispatch"
require "active_support"
require "active_support/isolated_execution_state"
require "active_support/notifications"

module Roast
  module Workflow
    class BaseWorkflow
      include Raix::ChatCompletion

      attr_accessor :file,
        :concise,
        :output_file,
        :verbose,
        :name,
        :context_path,
        :output,
        :resource,
        :session_name,
        :session_timestamp,
        :configuration

      def initialize(file = nil, name: nil, context_path: nil, resource: nil, session_name: nil, configuration: nil)
        @file = file
        @name = name || self.class.name.underscore.split("/").last
        @context_path = context_path || determine_context_path
        @final_output = []
        @output = {}
        @resource = resource || Roast::Resources.for(file)
        @session_name = session_name || @name
        @session_timestamp = nil
        @configuration = configuration
        transcript << { system: read_sidecar_prompt }
        Roast::Tools.setup_interrupt_handler(transcript)
        Roast::Tools.setup_exit_handler(self)
      end

      def append_to_final_output(message)
        @final_output << message
      end

      def final_output
        @final_output.join("\n\n")
      end

      # Override chat_completion to add instrumentation
      def chat_completion(**kwargs)
        start_time = Time.now
        model = kwargs[:openai] || "default"

        ActiveSupport::Notifications.instrument("roast.chat_completion.start", {
          model: model,
          parameters: kwargs.except(:openai),
        })

        result = super(**kwargs)
        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.chat_completion.complete", {
          success: true,
          model: model,
          parameters: kwargs.except(:openai),
          execution_time: execution_time,
          response_size: result.to_s.length,
        })

        result
      rescue => e
        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.chat_completion.error", {
          error: e.class.name,
          message: e.message,
          model: model,
          parameters: kwargs.except(:openai),
          execution_time: execution_time,
        })
        raise
      end

      private

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

      def read_sidecar_prompt
        Roast::Helpers::PromptLoader.load_prompt(self, file)
      end
    end
  end
end
