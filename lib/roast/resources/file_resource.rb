# frozen_string_literal: true

module Roast
  module Resources
    # Resource implementation for files
    class FileResource < BaseResource
      def process
        # Handle glob patterns in the target
        if target.include?("*") || target.include?("?")
          Dir.glob(target).map { |f| File.expand_path(f) unless Dir.exist?(f) }.compact.join("\n")
        else
          File.expand_path(target)
        end
      end

      def exists?
        File.exist?(target) && !Dir.exist?(target)
      end

      def contents
        File.read(target) if exists?
      end

      def name
        File.basename(target) if target
      end

      def type
        :file
      end
    end
  end
end
