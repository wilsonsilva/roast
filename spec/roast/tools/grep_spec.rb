# frozen_string_literal: true

require "spec_helper"
require "roast/tools/grep"
require "tempfile"
require "fileutils"

RSpec.describe(Roast::Tools::Grep) do
  let(:temp_dir) { Dir.mktmpdir("grep_test_dir") }
  let(:test_file1) { File.join(temp_dir, "test_file1.txt") }
  let(:test_file2) { File.join(temp_dir, "nested", "test_file2.txt") }
  let(:original_dir) { Dir.pwd }

  before do
    # Create test files
    FileUtils.mkdir_p(File.dirname(test_file1))
    FileUtils.mkdir_p(File.dirname(test_file2))

    File.write(
      test_file1,
      "This is a test file with some content\nIt has multiple lines\nAnd some searchable text",
    )
    File.write(test_file2, "Another test file\nWith different content\nBut also searchable")

    # Change to temp directory
    Dir.chdir(temp_dir)
  end

  after do
    # Restore original directory and cleanup
    Dir.chdir(original_dir) if Dir.pwd != original_dir
    FileUtils.remove_entry(temp_dir) if File.exist?(temp_dir)
  end

  describe ".call" do
    it "executes ripgrep command with correct format" do
      expected_command = "rg -C 4 " \
        "--trim --color=never --heading -F -- \"searchable\" . | head -n #{described_class::MAX_RESULT_LINES}"

      allow(described_class).to(receive(:`).with(expected_command).and_return("mock search results"))

      result = described_class.call("searchable")
      expect(result).to(eq("mock search results"))
    end

    it "handles errors gracefully" do
      allow(described_class).to(receive(:`).and_raise(StandardError, "Command failed"))

      result = described_class.call("searchable")
      expect(result).to(eq("Error grepping for string: Command failed"))
    end

    it "escapes curly braces properly" do
      search_string = "import {render}"
      expected_escaped = "import \\{render\\}"
      expected_command = "rg -C 4 " \
        "--trim --color=never --heading -F -- \"#{expected_escaped}\" . | head -n #{described_class::MAX_RESULT_LINES}"

      allow(described_class).to(receive(:`).with(expected_command).and_return("mock search results"))

      result = described_class.call(search_string)
      expect(result).to(eq("mock search results"))
    end
  end

  describe ".included" do
    let(:base_class) do
      Class.new do
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
    end

    it "adds function to the base class" do
      described_class.included(base_class)

      expect(base_class.function_called).to(be(true))
      expect(base_class.function_name).to(eq(:grep))
    end
  end
end
