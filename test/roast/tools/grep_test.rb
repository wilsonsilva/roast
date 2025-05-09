# frozen_string_literal: true

require "test_helper"
require "roast/tools/grep"
require "tempfile"
require "fileutils"

class RoastToolsGrepTest < ActiveSupport::TestCase
  def setup
    @temp_dir = Dir.mktmpdir("grep_test_dir")
    @test_file1 = File.join(@temp_dir, "test_file1.txt")
    @test_file2 = File.join(@temp_dir, "nested", "test_file2.txt")
    @original_dir = Dir.pwd

    FileUtils.mkdir_p(File.dirname(@test_file1))
    FileUtils.mkdir_p(File.dirname(@test_file2))

    File.write(
      @test_file1,
      "This is a test file with some content\nIt has multiple lines\nAnd some searchable text",
    )
    File.write(@test_file2, "Another test file\nWith different content\nBut also searchable")

    Dir.chdir(@temp_dir)
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
    FileUtils.remove_entry(@temp_dir) if File.exist?(@temp_dir)
  end

  test "executes ripgrep command with correct format" do
    expected_command = "rg -C 4 " \
      "--trim --color=never --heading -F -- \"searchable\" . | head -n #{Roast::Tools::Grep::MAX_RESULT_LINES}"
    actual_command = nil

    # Stub Kernel backtick operator for this test only
    Roast::Tools::Grep.singleton_class.class_eval do
      alias_method(:orig_backtick, :`)
      define_method(:`, ->(cmd) {
        actual_command = cmd
        "mock search results"
      })
    end

    result = Roast::Tools::Grep.call("searchable")
    assert_equal(expected_command, actual_command)
    assert_equal("mock search results", result)
  ensure
    # Restore original backtick
    Roast::Tools::Grep.singleton_class.class_eval do
      remove_method(:`)
      alias_method(:`, :orig_backtick)
      remove_method(:orig_backtick)
    end
  end

  test "handles errors gracefully" do
    # Stub Kernel backtick operator to raise error
    Roast::Tools::Grep.singleton_class.class_eval do
      alias_method(:orig_backtick, :`)
      define_method(:`, ->(_cmd) { raise StandardError, "Command failed" })
    end

    result = Roast::Tools::Grep.call("searchable")
    assert_equal("Error grepping for string: Command failed", result)
  ensure
    # Restore original backtick
    Roast::Tools::Grep.singleton_class.class_eval do
      remove_method(:`)
      alias_method(:`, :orig_backtick)
      remove_method(:orig_backtick)
    end
  end

  test "escapes curly braces properly" do
    search_string = "import {render}"
    expected_escaped = "import \\{render\\}"
    expected_command = "rg -C 4 " \
      "--trim --color=never --heading -F -- \"#{expected_escaped}\" . | head -n #{Roast::Tools::Grep::MAX_RESULT_LINES}"
    actual_command = nil

    Roast::Tools::Grep.singleton_class.class_eval do
      alias_method(:orig_backtick, :`)
      define_method(:`, ->(cmd) {
        actual_command = cmd
        "mock search results"
      })
    end

    result = Roast::Tools::Grep.call(search_string)
    assert_equal(expected_command, actual_command)
    assert_equal("mock search results", result)
  ensure
    Roast::Tools::Grep.singleton_class.class_eval do
      remove_method(:`)
      alias_method(:`, :orig_backtick)
      remove_method(:orig_backtick)
    end
  end

  test ".included adds function to the base class" do
    base_class = Class.new do
      class << self
        attr_reader :function_name, :function_called

        def function(name, description, **params, &block)
          @function_called = true
          @function_name = name
          @function_description = description
          @function_params = params
          @function_block = block
        end
      end
    end

    Roast::Tools::Grep.included(base_class)

    assert base_class.function_called, "Expected function to be called"
    assert_equal :grep, base_class.function_name
  end
end
