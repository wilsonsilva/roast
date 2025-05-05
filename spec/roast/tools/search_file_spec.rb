# frozen_string_literal: true

require "spec_helper"
require "roast/tools/search_file"
require "roast/tools/read_file"
require "tempfile"
require "fileutils"

RSpec.describe(Roast::Tools::SearchFile) do
  let(:temp_dir) { Dir.mktmpdir("search_file_test_dir") }
  let(:test_file1) { File.join(temp_dir, "test_file1.txt") }
  let(:test_file2) { File.join(temp_dir, "nested", "test_file2.txt") }
  let(:test_file3) { File.join(temp_dir, "nested", "deep", "test_file3.rb") }
  let(:original_dir) { Dir.pwd }

  before do
    # Create test files
    FileUtils.mkdir_p(File.dirname(test_file1))
    FileUtils.mkdir_p(File.dirname(test_file2))
    FileUtils.mkdir_p(File.dirname(test_file3))

    File.write(test_file1, "content 1")
    File.write(test_file2, "content 2")
    File.write(test_file3, "content 3")

    # Change to temp directory
    Dir.chdir(temp_dir)
  end

  after do
    # Restore original directory
    Dir.chdir(original_dir) if Dir.pwd != original_dir
    FileUtils.remove_entry(temp_dir) if File.exist?(temp_dir)
  end

  describe ".search_for" do
    it "returns matching files" do
      # Remove the temp_dir prefix for relative paths
      rel_file1 = test_file1.sub("#{temp_dir}/", "")
      rel_file2 = test_file2.sub("#{temp_dir}/", "")
      rel_file3 = test_file3.sub("#{temp_dir}/", "")

      # Test exact match
      results = described_class.search_for("test_file1.txt")
      expect(results).to(include(rel_file1))

      # Test partial match
      results = described_class.search_for("test_file")
      expect(results).to(include(rel_file1, rel_file2, rel_file3))

      # Test extension match
      results = described_class.search_for(".rb")
      expect(results).to(include(rel_file3))
      expect(results).not_to(include(rel_file1, rel_file2))

      # Test directory match
      results = described_class.search_for("nested")
      expect(results).to(include(rel_file2, rel_file3))
      expect(results).not_to(include(rel_file1))
    end
  end

  describe ".call" do
    it "returns file content for single match" do
      allow(described_class).to(receive(:search_for).and_return(["test_file1.txt"]))
      allow(Roast::Tools::ReadFile).to(receive(:call).and_return("file content"))

      result = described_class.call("test_file1.txt")
      expect(result).to(eq("file content"))
    end

    it "returns file list for multiple matches" do
      allow(described_class).to(receive(:search_for).and_return(["file1.txt", "file2.txt"]))

      result = described_class.call("file")
      expect(result).to(eq(["file1.txt", "file2.txt"].inspect))
    end

    it "returns no results message when empty" do
      allow(described_class).to(receive(:search_for).and_return([]))

      result = described_class.call("nonexistent")
      expect(result).to(eq("No results found for nonexistent"))
    end

    it "handles errors gracefully" do
      allow(described_class).to(receive(:search_for).and_raise(StandardError, "Search failed"))

      result = described_class.call("test_file")
      expect(result).to(eq("Error searching for file: Search failed"))
    end
  end

  describe ".included" do
    let(:base_class) do
      Class.new do
        class << self
          attr_reader :function_called,
            :function_name,
            :function_description,
            :function_params,
            :function_block

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
      expect(base_class.function_name).to(eq(:search_for_file))
    end
  end
end
