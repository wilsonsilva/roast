# frozen_string_literal: true

require "test_helper"

module Roast
  class InitializersTest < ActiveSupport::TestCase
    def test_with_invalid_initializers_folder
      invalid_initializer_path = File.join(Dir.pwd, "test", "fixtures", "invalid")

      Roast::Initializers.stub(:initializers_path, invalid_initializer_path) do
        out, err = capture_io do
          Roast::Initializers.load_all
        end

        assert_equal("", out)
        assert_equal("", err)
      end
    end

    def test_with_no_initializer_files
      empty_initializer_path = File.join(Dir.pwd, "test", "fixtures", "initializers", "empty")

      Roast::Initializers.stub(:initializers_path, empty_initializer_path) do
        out, err = capture_io do
          Roast::Initializers.load_all
        end

        assert_equal("", out)
        expected_output = <<~OUTPUT
          Loading project initializers from #{empty_initializer_path}
        OUTPUT
        assert_equal(expected_output, err)
      end
    end

    def test_with_an_initializer_file
      test_initializer_path = File.join(Dir.pwd, "test", "fixtures", "initializers")

      Roast::Initializers.stub(:initializers_path, test_initializer_path) do
        out, err = capture_io do
          Roast::Initializers.load_all
        end

        assert_equal("", out)
        expected_output = <<~OUTPUT
          Loading project initializers from #{test_initializer_path}
          Loading initializer: #{File.join(test_initializer_path, "noop.rb")}
        OUTPUT
        assert_equal(expected_output, err)
      end
    end
  end
end
