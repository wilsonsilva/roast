# frozen_string_literal: true

require "test_helper"
require "securerandom"
require "tmpdir"

class RoastTest < Minitest::Test
  def test_roast_root_constant
    # Simply check that the ROAST_ROOT constant is properly set
    # and that it points to the expected directory structure
    assert_equal("roast", File.basename(Roast::ROOT))
    assert(File.directory?(Roast::ROOT), "Roast::ROOT should be a directory")
  end
end
