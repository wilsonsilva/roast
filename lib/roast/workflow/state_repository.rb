# frozen_string_literal: true

module Roast
  module Workflow
    # Interface for state persistence operations
    # Handles saving and loading workflow state in a thread-safe manner
    class StateRepository
      def save_state(workflow, step_name, state_data)
        raise NotImplementedError, "#{self.class} must implement save_state"
      end

      def load_state_before_step(workflow, step_name, timestamp: nil)
        raise NotImplementedError, "#{self.class} must implement load_state_before_step"
      end

      def save_final_output(workflow, output_content)
        raise NotImplementedError, "#{self.class} must implement save_final_output"
      end
    end
  end
end
