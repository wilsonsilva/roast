# frozen_string_literal: true

require "roast"

module Roast
  module EntryPoint
    class << self
      def call(args)
        cmd, command_name, args = Roast::Resolver.call(args)
        Roast::Executor.call(cmd, command_name, args)
      end
    end
  end
end
