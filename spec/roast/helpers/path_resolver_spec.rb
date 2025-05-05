# frozen_string_literal: true

require "spec_helper"
require "roast/helpers/path_resolver"

RSpec.describe(Roast::Helpers::PathResolver) do
  let(:temp_dir) { File.join(Dir.pwd, "tmp", "path_resolver_test") }
  let(:project_dir) { File.join(temp_dir, "project") }
  let(:src_dir) { File.join(project_dir, "src") }
  let(:lib_dir) { File.join(src_dir, "lib") }
  let(:test_dir) { File.join(project_dir, "test") }
  let(:test_file) { File.join(test_dir, "test_file.rb") }
  let(:lib_file) { File.join(lib_dir, "lib_file.rb") }
  let(:original_dir) { Dir.pwd }

  before do
    # Create a temporary directory structure for testing path resolution
    FileUtils.mkdir_p(lib_dir)
    FileUtils.mkdir_p(test_dir)

    # Create the test files
    File.write(test_file, "# Test file")
    File.write(lib_file, "# Lib file")
  end

  after do
    # Return to the original directory
    Dir.chdir(original_dir) if Dir.pwd != original_dir

    # Clean up our temp directory
    FileUtils.rm_rf(temp_dir) if File.exist?(temp_dir)
  end

  describe ".resolve" do
    it "resolves duplicate path segments" do
      # Create a path with duplicated segments
      duplicated_path = lib_file.gsub(temp_dir, "#{temp_dir}/#{File.basename(temp_dir)}")

      # Test that our path resolver removes the duplicates
      resolved = described_class.resolve(duplicated_path)
      expect(resolved).to(eq(lib_file))
    end

    it "resolves paths from parent directory" do
      # Change directory to project/src
      Dir.chdir(src_dir)

      # Try to resolve a path that's relative to a different directory
      relative_path = "../test/test_file.rb"
      resolved = described_class.resolve(relative_path)

      expect(resolved).to(eq(test_file))
    end

    it "resolves paths from different working directory" do
      # Change to a subdirectory
      Dir.chdir(lib_dir)

      # Resolve a path to the test file
      resolved = described_class.resolve(test_file)

      expect(resolved).to(eq(test_file))
    end

    it "resolves paths with common root" do
      # Test when path shares a common root with pwd
      Dir.chdir(project_dir)

      resolved = described_class.resolve("src/lib/lib_file.rb")
      expect(resolved).to(eq(lib_file))
    end

    it "handles nonexistent files" do
      # Test that it still gives a reasonable path even if the file doesn't exist
      nonexistent = File.join(project_dir, "nonexistent.rb")
      resolved = described_class.resolve(nonexistent)

      expect(resolved).to(eq(nonexistent))
    end
  end
end
