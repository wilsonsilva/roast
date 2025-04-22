# frozen_string_literal: true

require "roast"

module Roast
  module Commands
    class Help < Roast::Command
      def call(args, _name)
        puts CLI::UI.fmt("{{bold:Available commands}}")
        puts ""

        Roast::Commands::Registry.resolved_commands.each do |name, klass|
          next if name == "help"

          puts CLI::UI.fmt("{{command:#{Roast::TOOL_NAME} #{name}}}")
          if (help = klass.help)
            puts CLI::UI.fmt(help)
          end
          puts ""
        end
      end
    end
  end
end
