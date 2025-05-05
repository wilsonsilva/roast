# frozen_string_literal: true

require "spec_helper"
require "roast/tools/write_file"
require "tempfile"
require "fileutils"

RSpec.describe(Roast::Tools::WriteFile) do
  let(:temp_dir) { File.join(Dir.pwd, "test", "tmp", "write_file_test_dir_#{Time.now.to_i}") }
  let(:test_file_path) { File.join(temp_dir, "test_file.txt") }
  let(:relative_test_file_path) { test_file_path.sub("#{Dir.pwd}/", "") }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.remove_entry(temp_dir) if File.exist?(temp_dir)
  end

  describe ".call" do
    it "creates file with content" do
      content = "test content"
      result = described_class.call(relative_test_file_path, content)

      expect(File.exist?(test_file_path)).to(be(true))
      expect(File.read(test_file_path)).to(eq(content))
      expect(result).to(match(/Successfully wrote 1 lines to/))
    end

    it "creates directories if needed" do
      nested_dir = File.join(temp_dir, "nested", "dir")
      nested_file = File.join(nested_dir, "test_file.txt")
      relative_nested_file = nested_file.sub("#{Dir.pwd}/", "")
      content = "nested content"

      described_class.call(relative_nested_file, content)

      expect(File.exist?(nested_file)).to(be(true))
      expect(File.read(nested_file)).to(eq(content))
    end

    it "overwrites existing file" do
      # Create file first
      FileUtils.mkdir_p(File.dirname(test_file_path))
      File.write(test_file_path, "original content")

      # Then overwrite it
      new_content = "new content"
      described_class.call(relative_test_file_path, new_content)

      expect(File.read(test_file_path)).to(eq(new_content))
    end

    it "returns error for invalid path" do
      result = described_class.call("invalid/path.txt", "content")
      expect(result).to(eq("Error: Path must start with 'test/' to use the write_file tool, try again."))
    end

    it "handles permission errors" do
      FileUtils.mkdir_p(File.dirname(test_file_path))
      FileUtils.chmod(0o000, File.dirname(test_file_path))

      result = described_class.call(relative_test_file_path, "content")
      expect(result).to(match(/Error writing file: Permission denied/))

      # Clean up permissions
      FileUtils.chmod(0o755, File.dirname(test_file_path))
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
      expect(base_class.function_name).to(eq(:write_file))
    end
  end
end
