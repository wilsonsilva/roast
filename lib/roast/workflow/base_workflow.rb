# frozen_string_literal: true

require "raix/chat_completion"
require "raix/function_dispatch"

module Roast
  module Workflow
    class BaseWorkflow
      include Raix::ChatCompletion

      attr_accessor :file,
        :concise,
        :output_file,
        :subject_file,
        :verbose,
        :name,
        :context_path,
        :output

      def initialize(file, subject_file = nil, name: nil, context_path: nil)
        @file = file
        @subject_file = subject_file
        @name = name || self.class.name.underscore.split("/").last
        @context_path = context_path || determine_context_path
        @final_output = []
        @output = {}
        transcript << { system: read_sidecar_prompt }
        unless subject_file.blank?
          transcript << { user: read_subject_file }
        end
        Roast::Tools.setup_interrupt_handler(transcript)
        Roast::Tools.setup_exit_handler(self)
      end

      def append_to_final_output(message)
        @final_output << message
      end

      def final_output
        @final_output.join("\n")
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

      def read_subject_file
        [
          "# SUT (Subject Under Test)",
          "# #{subject_file}",
          File.read(subject_file),
        ].join("\n")
      end
    end
  end
end
