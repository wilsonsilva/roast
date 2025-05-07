# frozen_string_literal: true

module Roast
  module Resources
    # Resource implementation for directories
    class DirectoryResource < BaseResource
      def process
        if target.include?("*") || target.include?("?")
          # If it's a glob pattern, return only directories
          Dir.glob(target).select { |f| Dir.exist?(f) }.map { |d| File.expand_path(d) }.join("\n")
        else
          File.expand_path(target)
        end
      end

      def exists?
        Dir.exist?(target)
      end

      def contents
        # Return a listing of files in the directory
        if exists?
          Dir.entries(target).reject { |f| f == "." || f == ".." }.join("\n")
        end
      end

      def name
        if target
          File.basename(target) + "/"
        else
          "Unnamed Directory"
        end
      end

      def type
        :directory
      end
    end
  end
end
