# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

module Roast
  module Tools
    class WriteFileTest < Minitest::Test
      def setup
        # Create a temporary directory within the test directory
        @temp_dir = File.join(Dir.pwd, "test", "tmp", "write_file_test_dir_#{Time.now.to_i}")
        FileUtils.mkdir_p(@temp_dir)
        @test_file_path = File.join(@temp_dir, "test_file.txt")
        # Make sure the path starts with 'test/'
        @relative_test_file_path = @test_file_path.sub("#{Dir.pwd}/", "")
      end

      def teardown
        FileUtils.remove_entry(@temp_dir) if File.exist?(@temp_dir)
      end

      def test_write_file_creates_file_with_content
        content = "test content"
        result = WriteFile.call(@relative_test_file_path, content)

        assert(File.exist?(@test_file_path))
        assert_equal(content, File.read(@test_file_path))
        assert_match(/Successfully wrote 1 lines to/, result)
      end

      def test_write_file_creates_directories_if_needed
        nested_dir = File.join(@temp_dir, "nested", "dir")
        nested_file = File.join(nested_dir, "test_file.txt")
        # Make sure the path starts with 'test/'
        relative_nested_file = nested_file.sub("#{Dir.pwd}/", "")
        content = "nested content"

        WriteFile.call(relative_nested_file, content)

        assert(File.exist?(nested_file))
        assert_equal(content, File.read(nested_file))
      end

      def test_write_file_overwrites_existing_file
        # Create file first
        FileUtils.mkdir_p(File.dirname(@test_file_path))
        File.write(@test_file_path, "original content")

        # Then overwrite it
        new_content = "new content"
        WriteFile.call(@relative_test_file_path, new_content)

        assert_equal(new_content, File.read(@test_file_path))
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

        WriteFile.included(base)

        assert(base.function_called?)
        assert_equal(:write_file, base.function_name)
      end

      def test_write_file_handles_errors
        # Try to write to a path that doesn't start with 'test/'
        result = WriteFile.call("invalid/path.txt", "content")
        assert_equal("Error: Path must start with 'test/' to use the write_file tool, try again.", result)

        # Try to write to a path where we don't have permissions
        FileUtils.mkdir_p(File.dirname(@test_file_path))
        FileUtils.chmod(0o000, File.dirname(@test_file_path))
        result = WriteFile.call(@relative_test_file_path, "content")
        assert_match(/Error writing file: Permission denied/, result)
        FileUtils.chmod(0o755, File.dirname(@test_file_path))
      end
    end
  end
end
