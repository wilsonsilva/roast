# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Roast::Resources) do
  describe ".for" do
    it "creates a FileResource for file paths" do
      file_path = __FILE__
      resource = described_class.for(file_path)
      expect(resource).to(be_a(Roast::Resources::FileResource))
    end

    it "creates a DirectoryResource for directory paths" do
      dir_path = File.dirname(__FILE__)
      resource = described_class.for(dir_path)
      expect(resource).to(be_a(Roast::Resources::DirectoryResource))
    end

    it "creates a UrlResource for URLs" do
      url = "https://example.com/api"
      resource = described_class.for(url)
      expect(resource).to(be_a(Roast::Resources::UrlResource))
    end

    it "creates an ApiResource for Fetch API style configurations" do
      config = {
        url: "https://api.example.com/resource",
        options: {
          method: "GET",
          headers: {
            "Authorization": "Bearer token",
          },
        },
      }.to_json
      resource = described_class.for(config)
      expect(resource).to(be_a(Roast::Resources::ApiResource))
    end

    it "creates a NoneResource for nil target" do
      resource = described_class.for(nil)
      expect(resource).to(be_a(Roast::Resources::NoneResource))
    end

    it "creates a NoneResource for empty target" do
      resource = described_class.for("")
      expect(resource).to(be_a(Roast::Resources::NoneResource))
    end
  end

  describe ".detect_type" do
    it "returns :file for existing files" do
      expect(described_class.detect_type(__FILE__)).to(eq(:file))
    end

    it "returns :directory for existing directories" do
      expect(described_class.detect_type(File.dirname(__FILE__))).to(eq(:directory))
    end

    it "returns :url for URLs with http/https scheme" do
      expect(described_class.detect_type("https://example.com")).to(eq(:url))
      expect(described_class.detect_type("http://example.com")).to(eq(:url))
      expect(described_class.detect_type("ftp://example.com")).to(eq(:url))
    end

    it "returns :api for Fetch API style JSON configurations" do
      config = {
        url: "https://api.example.com/resource",
        options: {
          method: "GET",
        },
      }.to_json
      expect(described_class.detect_type(config)).to(eq(:api))
    end

    it "returns :none for nil target" do
      expect(described_class.detect_type(nil)).to(eq(:none))
    end

    it "returns :none for empty target" do
      expect(described_class.detect_type("")).to(eq(:none))
      expect(described_class.detect_type("  ")).to(eq(:none))
    end

    it "returns :file for file-like targets that don't exist yet" do
      expect(described_class.detect_type("/nonexistent/file.txt")).to(eq(:file))
    end
  end
end
