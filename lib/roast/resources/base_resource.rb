# frozen_string_literal: true

module Roast
  module Resources
    # Base class for all resource types
    # Follows the Strategy pattern to handle different resource types in a polymorphic way
    class BaseResource
      attr_reader :target

      # Initialize a resource with a target
      # @param target [String] The target specified in the workflow, can be nil
      def initialize(target)
        @target = target
      end

      # Process the resource to prepare it for use
      # @return [String] The processed target
      def process
        target
      end

      # Check if the resource exists
      # @return [Boolean] true if the resource exists
      def exists?
        false # Override in subclasses
      end

      # Get the contents of the resource
      # @return [String] The contents of the resource
      def contents
        nil # Override in subclasses
      end

      # Get a name for the resource to display in logs
      # @return [String] A descriptive name for the resource
      def name
        target || "Unnamed Resource"
      end

      # Get the type of this resource as a symbol
      # @return [Symbol] The resource type
      def type
        :unknown
      end
    end
  end
end
