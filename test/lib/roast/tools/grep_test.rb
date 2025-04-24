# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

module Roast
  module Tools
    class GrepTest < Minitest::Test
      def setup
        @temp_dir = Dir.mktmpdir("grep_test_dir")

        # Create a few test files with content
        @test_file1 = File.join(@temp_dir, "test_file1.txt")
        @test_file2 = File.join(@temp_dir, "nested", "test_file2.txt")

        FileUtils.mkdir_p(File.dirname(@test_file1))
        FileUtils.mkdir_p(File.dirname(@test_file2))

        File.write(
          @test_file1,
          "This is a test file with some content\nIt has multiple lines\nAnd some searchable text",
        )
        File.write(@test_file2, "Another test file\nWith different content\nBut also searchable")

        # Store current directory to restore later
        @original_dir = Dir.pwd
        Dir.chdir(@temp_dir)
      end

      def teardown
        # Restore original directory
        Dir.chdir(@original_dir)
        FileUtils.remove_entry(@temp_dir)
      end

      def test_call_executes_ripgrep_command
        # We'll use a mock to avoid actually executing the command
        # but verify the command format is correct
        expected_command = "rg -C 4 " \
          "--trim --color=never --heading -F -- \"searchable\" . | head -n #{Grep::MAX_RESULT_LINES}"

        # Mock the backtick method to return a fixed string and verify the command
        Grep.stub(:`, lambda { |cmd|
          assert_equal(expected_command, cmd)
          "mock search results"
        }) do
          result = Grep.call("searchable")
          assert_equal("mock search results", result)
        end
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

        Grep.included(base)

        assert(base.function_called?)
        assert_equal(:grep, base.function_name)
      end

      def test_call_handles_errors
        Grep.stub(:`, ->(_) { raise StandardError, "Command failed" }) do
          result = Grep.call("searchable")
          assert_equal("Error grepping for string: Command failed", result)
        end
      end

      def test_call_escapes_curly_braces
        # Test that curly braces are properly escaped
        search_string = "import {render}"
        expected_escaped = "import \\{render\\}"
        expected_command = "rg -C 4 " \
          "--trim --color=never --heading -F -- \"#{expected_escaped}\" . | head -n #{Grep::MAX_RESULT_LINES}"

        Grep.stub(:`, lambda { |cmd|
          assert_equal(expected_command, cmd)
          "mock search results"
        }) do
          result = Grep.call(search_string)
          assert_equal("mock search results", result)
        end
      end
    end
  end
end
