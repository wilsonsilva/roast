# frozen_string_literal: true

require "roast/helpers/logger"

module Roast
  module Tools
    module SearchFile
      extend self

      class << self
        # Add this method to be included in other classes
        def included(base)
          base.class_eval do
            function(
              :search_for_file,
              'Search for a file in the project using `find . -type f -path "*#{@file_name}*"` in the project root',
              name: { type: "string", description: "filename with as much of the path as you can deduce" },
            ) do |params|
              Roast::Tools::SearchFile.call(params[:name]).tap do |result|
                Roast::Helpers::Logger.debug(result) if ENV["DEBUG"]
              end
            end
          end
        end
      end

      def call(filename)
        Roast::Helpers::Logger.info("🔍 Searching for file: #{filename}\n")
        search_for(filename).then do |results|
          return "No results found for #{filename}" if results.empty?
          return Roast::Tools::ReadFile.call(results.first) if results.size == 1

          results.inspect # purposely give the AI list of actual paths so that it can read without searching first
        end
      rescue StandardError => e
        "Error searching for file: #{e.message}".tap do |error_message|
          Roast::Helpers::Logger.error(error_message + "\n")
          Roast::Helpers::Logger.debug(e.backtrace.join("\n") + "\n") if ENV["DEBUG"]
        end
      end

      def search_for(filename)
        # Execute find command and get the output using -path to match against full paths
        result = %x(find . -type f -path "*#{filename}*").strip

        # Split by newlines and get the first result
        result.split("\n").map(&:strip).reject(&:empty?).map { |path| path.sub(%r{^\./}, "") }
      end
    end
  end
end
