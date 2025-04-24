# frozen_string_literal: true

require "fileutils"
require "roast/support/logger"

module Roast
  module Tools
    module WriteFile
      extend self

      class << self
        # Add this method to be included in other classes
        def included(base)
          base.class_eval do
            function(
              :write_file,
              "Write content to a file. Creates the file if it does not exist, or overwrites it if it does.",
              path: {
                type: "string",
                description: "The path to the file to write, relative to the current working directory: #{Dir.pwd}",
              },
              content: { type: "string", description: "The content to write to the file" },
            ) do |params|
              Roast::Tools::WriteFile.call(params[:path], params[:content]).tap do |_result|
                Roast::Support::Logger.info(params[:content])
              end
            end
          end
        end
      end

      def call(path, content)
        if path.start_with?("test/")

          Roast::Support::Logger.info("📝 Writing to file: #{path}\n")

          # Ensure the directory exists
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir) unless File.directory?(dir)

          # Write the content to the file
          # Check if path is absolute or relative
          absolute_path = path.start_with?("/") ? path : File.join(Dir.pwd, path)

          File.write(absolute_path, content)

          "Successfully wrote #{content.lines.count} lines to #{path}"
        else
          Roast::Support::Logger.error("😳 Path must start with 'test/' to use the write_file tool\n")
          "Error: Path must start with 'test/' to use the write_file tool, try again."
        end
      rescue StandardError => e
        "Error writing file: #{e.message}".tap do |error_message|
          Roast::Support::Logger.error(error_message + "\n")
          Roast::Support::Logger.debug(e.backtrace.join("\n") + "\n") if ENV["DEBUG"]
        end
      end
    end
  end
end
