# frozen_string_literal: true

require "spec_helper"
require "roast/tools/read_file"
require "tempfile"
require "fileutils"

RSpec.describe(Roast::Tools::ReadFile) do
  let(:temp_dir) { Dir.mktmpdir("read_file_test_dir") }
  let(:original_dir) { Dir.pwd }

  before do
    # Create test file in temp directory
    FileUtils.touch(File.join(temp_dir, "test_file.txt"))

    # Change to temp directory
    Dir.chdir(temp_dir)
  end

  after do
    # Restore original directory
    Dir.chdir(original_dir) if Dir.pwd != original_dir
    FileUtils.remove_entry(temp_dir) if File.exist?(temp_dir)
  end

  describe ".call" do
    it "returns file contents when reading a file" do
      # Create a file in the current directory
      test_file = "test_file_content.txt"
      File.write(test_file, "test content")

      result = described_class.call(test_file)
      expect(result).to(eq("test content"))

      # Clean up
      File.unlink(test_file)
    end

    it "returns directory listing when reading a directory" do
      result = described_class.call(".")
      expect(result).to(match(/test_file\.txt/))
    end

    it "handles errors gracefully" do
      result = described_class.call("nonexistent_file.txt")
      expect(result).to(match(/Error reading file: No such file or directory/))
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
      expect(base_class.function_name).to(eq(:read_file))
    end
  end
end
