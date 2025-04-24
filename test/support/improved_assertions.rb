# frozen_string_literal: true

module Minitest
  module Assertions
    # Override the default assert_predicate to accept arguments for the predicate method
    def assert_predicate_with_args(obj, pred, *args, message: nil)
      result = obj.send(pred, *args)

      # Helper to truncate strings in output
      formatted_result = if result.is_a?(String) && result.length > 25
        "#{result[0...25]}..."
      else
        mu_pp(result)
      end

      # Format arguments for display
      formatted_args = args.map { |a| mu_pp(a) }.join(", ")

      msg = message(message) do
        if result
          "Expected #{formatted_result} not to #{pred} with #{formatted_args}"
        else
          "Expected #{mu_pp(obj)} to #{pred} with #{formatted_args}"
        end
      end

      assert(result, msg)
    end
  end
end

module Minitest
  class Test
    # Add a convenient alias that's more intuitive
    alias_method :assert_predicate_original, :assert_predicate

    # Override assert_predicate to handle both cases:
    # 1. Traditional usage: assert_predicate(obj, :method)
    # 2. Extended usage: assert_predicate(obj, :method, arg1, arg2, ..., message: "Optional message")
    def assert_predicate(obj, pred, *args, **kwargs)
      if args.empty? && kwargs.empty?
        # Original behavior when no args provided
        assert_predicate_original(obj, pred)
      else
        # Use our new method with arguments
        assert_predicate_with_args(obj, pred, *args, **kwargs)
      end
    end
  end
end
