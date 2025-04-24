# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

module Roast
  module Tools
    class SearchFileTest < Minitest::Test
      def setup
        @temp_dir = Dir.mktmpdir("search_file_test_dir")

        # Create a few test files
        @test_file1 = File.join(@temp_dir, "test_file1.txt")
        @test_file2 = File.join(@temp_dir, "nested", "test_file2.txt")
        @test_file3 = File.join(@temp_dir, "nested", "deep", "test_file3.rb")

        FileUtils.mkdir_p(File.dirname(@test_file1))
        FileUtils.mkdir_p(File.dirname(@test_file2))
        FileUtils.mkdir_p(File.dirname(@test_file3))

        File.write(@test_file1, "content 1")
        File.write(@test_file2, "content 2")
        File.write(@test_file3, "content 3")

        # Store current directory to restore later
        @original_dir = Dir.pwd
        Dir.chdir(@temp_dir)
      end

      def teardown
        # Restore original directory
        Dir.chdir(@original_dir)
        FileUtils.remove_entry(@temp_dir)
      end

      def test_search_for_returns_matching_files
        # Remove the temp_dir prefix for relative paths
        rel_file1 = @test_file1.sub("#{@temp_dir}/", "")
        rel_file2 = @test_file2.sub("#{@temp_dir}/", "")
        rel_file3 = @test_file3.sub("#{@temp_dir}/", "")

        # Test exact match
        results = SearchFile.search_for("test_file1.txt")
        assert_includes(results, rel_file1)

        # Test partial match
        results = SearchFile.search_for("test_file")
        assert_includes(results, rel_file1)
        assert_includes(results, rel_file2)
        assert_includes(results, rel_file3)

        # Test extension match
        results = SearchFile.search_for(".rb")
        assert_includes(results, rel_file3)
        refute_includes(results, rel_file1)
        refute_includes(results, rel_file2)

        # Test directory match
        results = SearchFile.search_for("nested")
        assert_includes(results, rel_file2)
        assert_includes(results, rel_file3)
        refute_includes(results, rel_file1)
      end

      def test_call_returns_file_content_for_single_match
        # Mock the search_for method to return a single result
        SearchFile.stub(:search_for, ["test_file1.txt"]) do
          # Mock ReadFile.call to return a fixed string
          ReadFile.stub(:call, "file content") do
            result = SearchFile.call("test_file1.txt")
            assert_equal("file content", result)
          end
        end
      end

      def test_call_returns_file_list_for_multiple_matches
        # Mock the search_for method to return multiple results
        SearchFile.stub(:search_for, ["file1.txt", "file2.txt"]) do
          result = SearchFile.call("file")
          assert_equal(["file1.txt", "file2.txt"].inspect, result)
        end
      end

      def test_call_returns_no_results_message_when_empty
        # Mock the search_for method to return no results
        SearchFile.stub(:search_for, []) do
          result = SearchFile.call("nonexistent")
          assert_equal("No results found for nonexistent", result)
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

        SearchFile.included(base)

        assert(base.function_called?)
        assert_equal(:search_for_file, base.function_name)
      end

      def test_call_handles_errors
        SearchFile.stub(:search_for, ->(_) { raise StandardError, "Search failed" }) do
          result = SearchFile.call("test_file")
          assert_equal("Error searching for file: Search failed", result)
        end
      end
    end
  end
end
