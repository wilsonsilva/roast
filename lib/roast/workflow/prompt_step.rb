# frozen_string_literal: true

module Roast
  module Workflow
    class PromptStep < BaseStep
      def initialize(workflow, **kwargs)
        super(workflow, **kwargs)
      end

      def call
        prompt(name)
        chat_completion(auto_loop: false, print_response: true)
      end
    end
  end
end
