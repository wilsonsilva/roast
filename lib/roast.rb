# frozen_string_literal: true

require "cli/ui"
require "cli/kit"
require "roast/version"

CLI::UI::StdoutRouter.enable

module Roast
  TOOL_NAME = "roast"
  ROOT      = File.expand_path("../..", __FILE__)
  LOG_FILE  = "/tmp/roast.log"

  autoload(:EntryPoint, "roast/entry_point")
  autoload(:Commands,   "roast/commands")

  Config = CLI::Kit::Config.new(tool_name: TOOL_NAME)
  Command = CLI::Kit::BaseCommand

  Executor = CLI::Kit::Executor.new(log_file: LOG_FILE)
  Resolver = CLI::Kit::Resolver.new(
    tool_name: TOOL_NAME,
    command_registry: Roast::Commands::Registry,
  )

  ErrorHandler = CLI::Kit::ErrorHandler.new(log_file: LOG_FILE)
end
