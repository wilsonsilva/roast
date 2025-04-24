# frozen_string_literal: true

require "English"
require "pry"

require "roast/tools/grep"
require "roast/tools/read_file"
require "roast/tools/search_file"
require "roast/tools/write_file"
require "roast/tools/cmd"

module Roast
  module Tools
    extend self

    def file_to_prompt(file)
      <<~PROMPT
        # #{file}

        #{File.read(file)}
      PROMPT
    rescue StandardError => e
      Roast::Support::Logger.error("In current directory: #{Dir.pwd}\n")
      Roast::Support::Logger.error("Error reading file #{file}\n")

      raise e # unable to continue without required file
    end

    def setup_interrupt_handler(object_to_inspect)
      Signal.trap("INT") do
        puts "\n\nCaught CTRL-C! Printing before exiting:\n"
        puts JSON.pretty_generate(object_to_inspect)
        exit(1)
      end
    end

    def setup_exit_handler(context)
      # Hook that runs on any exit (including crashes and unhandled exceptions)
      at_exit do
        if $ERROR_INFO && !$ERROR_INFO.is_a?(SystemExit) # If exiting due to unhandled exception
          puts "\n\nExiting due to error: #{$ERROR_INFO.class}: #{$ERROR_INFO.message}\n"
          context.instance_eval { binding.pry } # rubocop:disable Lint/Debugger
        end
      end
    end
  end
end
