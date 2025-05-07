# frozen_string_literal: true

module Roast
  module Resources
    # Resource implementation for workflows with no target (targetless workflows)
    class NoneResource < BaseResource
      def process
        nil
      end

      def exists?
        # There's no target to check, so this is always true
        true
      end

      def contents
        nil
      end

      def name
        "Targetless Resource"
      end

      def type
        :none
      end
    end
  end
end
