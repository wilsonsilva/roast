# frozen_string_literal: true

require "roast"

module Roast
  module Commands
    class Example < Roast::Command
      def call(_args, _name)
        puts "neato"

        if rand < 0.5
          raise(CLI::Kit::Abort, "you got unlucky!")
        end
      end

      class << self
        def help
          "A dummy command.\nUsage: {{command:#{Roast::TOOL_NAME} example}}"
        end
      end
    end
  end
end
