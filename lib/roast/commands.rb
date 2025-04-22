# frozen_string_literal: true

require "roast"

module Roast
  module Commands
    Registry = CLI::Kit::CommandRegistry.new(default: "help")

    class << self
      def register(const, cmd, path)
        autoload(const, path)
        Registry.add(->() { const_get(const) }, cmd)
      end
    end

    register :Example, "example", "roast/commands/example"
    register :Help,    "help",    "roast/commands/help"
  end
end
