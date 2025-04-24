# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

module Roast
  module Tools
    class ReadFileTest < Minitest::Test
      def setup
        @temp_file = Tempfile.new("read_file_test")
        @temp_file.write("test content")
        @temp_file.close

        @temp_dir = Dir.mktmpdir("read_file_test_dir")
        FileUtils.touch(File.join(@temp_dir, "test_file.txt"))

        # Store current directory to restore later
        @original_dir = Dir.pwd
        Dir.chdir(@temp_dir)
      end

      def teardown
        # Restore original directory
        Dir.chdir(@original_dir)
        @temp_file.unlink
        FileUtils.remove_entry(@temp_dir)
      end

      def test_read_file_returns_file_contents
        # Create a file in the current directory
        test_file = "test_file_content.txt"
        File.write(test_file, "test content")

        result = ReadFile.call(test_file)
        assert_equal("test content", result)

        # Clean up
        File.unlink(test_file)
      end

      def test_read_directory_returns_directory_listing
        result = ReadFile.call(".")
        assert_match(/test_file\.txt/, result)
      end

      def test_included_adds_function_to_base
        base = Class.new do
          class << self
            def function(name, description, **params, &block)
              @function_called = true
              @function_name = name
              @function_description = description
              @function_params = params
              @function_block = block
            end

            def function_called?
              @function_called
            end

            attr_reader :function_name
          end
        end

        ReadFile.included(base)

        assert(base.function_called?)
        assert_equal(:read_file, base.function_name)
      end

      def test_read_file_handles_errors
        result = ReadFile.call("nonexistent_file.txt")
        assert_match(/Error reading file: No such file or directory/, result)
      end
    end
  end
end
