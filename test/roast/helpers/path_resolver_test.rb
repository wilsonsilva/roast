# frozen_string_literal: true

require "test_helper"
require "roast/helpers/path_resolver"
require "fileutils"

module Roast
  module Helpers
    class PathResolverTest < Minitest::Test
      def setup
        # Create a temporary directory structure for testing path resolution
        @temp_dir = File.join(Dir.pwd, "tmp", "path_resolver_test")
        FileUtils.mkdir_p(@temp_dir)

        # Create some nested directories and files to test with
        @project_dir = File.join(@temp_dir, "project")
        @src_dir = File.join(@project_dir, "src")
        @lib_dir = File.join(@src_dir, "lib")
        @test_dir = File.join(@project_dir, "test")

        FileUtils.mkdir_p(@lib_dir)
        FileUtils.mkdir_p(@test_dir)

        @test_file = File.join(@test_dir, "test_file.rb")
        @lib_file = File.join(@lib_dir, "lib_file.rb")

        # Create the test files
        File.write(@test_file, "# Test file")
        File.write(@lib_file, "# Lib file")

        # Store the original working directory
        @original_dir = Dir.pwd
      end

      def teardown
        # Return to the original directory
        Dir.chdir(@original_dir)

        # Clean up our temp directory
        FileUtils.rm_rf(@temp_dir) if File.exist?(@temp_dir)
      end

      def test_resolves_duplicate_path_segments
        # Create a path with duplicated segments
        duplicated_path = @lib_file.gsub(@temp_dir, "#{@temp_dir}/#{File.basename(@temp_dir)}")

        # Test that our path resolver removes the duplicates
        resolved = PathResolver.resolve(duplicated_path)
        assert_equal(@lib_file, resolved)
      end

      def test_resolves_from_parent_directory
        # Change directory to project/src
        Dir.chdir(@src_dir)

        # Try to resolve a path that's relative to a different directory
        relative_path = "../test/test_file.rb"
        resolved = PathResolver.resolve(relative_path)

        assert_equal(@test_file, resolved)
      end

      def test_resolves_from_different_working_directory
        # Change to a subdirectory
        Dir.chdir(@lib_dir)

        # Resolve a path to the test file
        resolved = PathResolver.resolve(@test_file)

        assert_equal(@test_file, resolved)
      end

      def test_resolves_path_with_common_root
        # Test when path shares a common root with pwd
        Dir.chdir(@project_dir)

        resolved = PathResolver.resolve("src/lib/lib_file.rb")
        assert_equal(@lib_file, resolved)
      end

      def test_handles_nonexistent_files
        # Test that it still gives a reasonable path even if the file doesn't exist
        nonexistent = File.join(@project_dir, "nonexistent.rb")
        resolved = PathResolver.resolve(nonexistent)

        assert_equal(nonexistent, resolved)
      end

      def test_debug_output
        # This test helps diagnose issues with path resolution
        Dir.chdir(@src_dir)

        # Output debugging information
        puts "\nDebugging PathResolver:"
        puts "Current directory: #{Dir.pwd}"
        puts "Project directory: #{@project_dir}"
        puts "Temp directory: #{@temp_dir}"

        test_path = "../test/test_file.rb"
        puts "Test path: #{test_path}"

        expanded = File.expand_path(test_path)
        puts "Simple expansion: #{expanded}"

        resolved = PathResolver.resolve(test_path)
        puts "Resolved path: #{resolved}"

        expected = @test_file
        puts "Expected path: #{expected}"

        assert_equal(expected, resolved)
      end
    end
  end
end
