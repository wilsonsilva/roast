# frozen_string_literal: true

require "minitest/autorun"
require "roast"

class RoastTest < Minitest::Test
  def test_has_a_version_number
    refute_nil(Roast::VERSION, "Roast::VERSION should not be nil")
  end
end
