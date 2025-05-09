# frozen_string_literal: true

require "test_helper"
require "roast/tools/search_file"
require "roast/tools/read_file"
require "tempfile"
require "fileutils"
require "mocha/minitest"

class RoastToolsSearchFileTest < ActiveSupport::TestCase
  def setup
    @temp_dir = Dir.mktmpdir("search_file_test_dir")
    @test_file1 = File.join(@temp_dir, "test_file1.txt")
    @test_file2 = File.join(@temp_dir, "nested", "test_file2.txt")
    @test_file3 = File.join(@temp_dir, "nested", "deep", "test_file3.rb")
    @original_dir = Dir.pwd

    FileUtils.mkdir_p(File.dirname(@test_file1))
    FileUtils.mkdir_p(File.dirname(@test_file2))
    FileUtils.mkdir_p(File.dirname(@test_file3))

    File.write(@test_file1, "content 1")
    File.write(@test_file2, "content 2")
    File.write(@test_file3, "content 3")

    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
    FileUtils.remove_entry(@temp_dir) if File.exist?(@temp_dir)
  end

  test ".search_for returns matching files" do
    rel_file1 = @test_file1.sub("#{@temp_dir}/", "")
    rel_file2 = @test_file2.sub("#{@temp_dir}/", "")
    rel_file3 = @test_file3.sub("#{@temp_dir}/", "")

    # Test exact match
    results = Roast::Tools::SearchFile.search_for("test_file1.txt")
    assert_includes results, rel_file1

    # Test partial match
    results = Roast::Tools::SearchFile.search_for("test_file")
    assert_includes results, rel_file1
    assert_includes results, rel_file2
    assert_includes results, rel_file3

    # Test extension match
    results = Roast::Tools::SearchFile.search_for(".rb")
    assert_includes results, rel_file3
    refute_includes results, rel_file1
    refute_includes results, rel_file2

    # Test directory match
    results = Roast::Tools::SearchFile.search_for("nested")
    assert_includes results, rel_file2
    assert_includes results, rel_file3
    refute_includes results, rel_file1
  end

  test ".call returns file content for single match" do
    Roast::Tools::SearchFile.stubs(:search_for).returns(["test_file1.txt"])
    Roast::Tools::ReadFile.stubs(:call).returns("file content")

    result = Roast::Tools::SearchFile.call("test_file1.txt")
    assert_equal "file content", result
  end

  test ".call returns file list for multiple matches" do
    Roast::Tools::SearchFile.stubs(:search_for).returns(["file1.txt", "file2.txt"])

    result = Roast::Tools::SearchFile.call("file")
    assert_equal ["file1.txt", "file2.txt"].inspect, result
  end

  test ".call returns no results message when empty" do
    Roast::Tools::SearchFile.stubs(:search_for).returns([])

    result = Roast::Tools::SearchFile.call("nonexistent")
    assert_equal "No results found for nonexistent", result
  end

  test ".call handles errors gracefully" do
    Roast::Tools::SearchFile.stubs(:search_for).raises(StandardError, "Search failed")

    result = Roast::Tools::SearchFile.call("test_file")
    assert_equal "Error searching for file: Search failed", result
  end

  class DummyBaseClass
    class << self
      attr_reader :function_called, :function_name, :function_description, :function_params, :function_block

      def function(name, description, **params, &block)
        @function_called = true
        @function_name = name
        @function_description = description
        @function_params = params
        @function_block = block
      end
    end
  end

  test ".included adds function to the base class" do
    Roast::Tools::SearchFile.included(DummyBaseClass)
    assert_equal true, DummyBaseClass.function_called
    assert_equal :search_for_file, DummyBaseClass.function_name
  end
end
