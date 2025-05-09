# frozen_string_literal: true

require "test_helper"

module Roast
  class ResourcesTest < ActiveSupport::TestCase
    class ForTest < ActiveSupport::TestCase
      test "creates a FileResource for file paths" do
        file_path = __FILE__
        resource = Resources.for(file_path)
        assert_instance_of(Resources::FileResource, resource)
      end

      test "creates a DirectoryResource for directory paths" do
        dir_path = File.dirname(__FILE__)
        resource = Resources.for(dir_path)
        assert_instance_of(Resources::DirectoryResource, resource)
      end

      test "creates a UrlResource for URLs" do
        url = "https://example.com/api"
        resource = Resources.for(url)
        assert_instance_of(Resources::UrlResource, resource)
      end

      test "creates an ApiResource for Fetch API style configurations" do
        config = {
          url: "https://api.example.com/resource",
          options: {
            method: "GET",
            headers: {
              "Authorization": "Bearer token",
            },
          },
        }.to_json
        resource = Resources.for(config)
        assert_instance_of(Resources::ApiResource, resource)
      end

      test "creates a NoneResource for nil target" do
        resource = Resources.for(nil)
        assert_instance_of(Resources::NoneResource, resource)
      end

      test "creates a NoneResource for empty target" do
        resource = Resources.for("")
        assert_instance_of(Resources::NoneResource, resource)
      end
    end

    class DetectTypeTest < ActiveSupport::TestCase
      test "returns :file for existing files" do
        assert_equal(:file, Resources.detect_type(__FILE__))
      end

      test "returns :directory for existing directories" do
        assert_equal(:directory, Resources.detect_type(File.dirname(__FILE__)))
      end

      test "returns :url for URLs with http/https scheme" do
        assert_equal(:url, Resources.detect_type("https://example.com"))
        assert_equal(:url, Resources.detect_type("http://example.com"))
        assert_equal(:url, Resources.detect_type("ftp://example.com"))
      end

      test "returns :api for Fetch API style JSON configurations" do
        config = {
          url: "https://api.example.com/resource",
          options: {
            method: "GET",
          },
        }.to_json
        assert_equal(:api, Resources.detect_type(config))
      end

      test "returns :none for nil target" do
        assert_equal(:none, Resources.detect_type(nil))
      end

      test "returns :none for empty target" do
        assert_equal(:none, Resources.detect_type(""))
        assert_equal(:none, Resources.detect_type("  "))
      end

      test "returns :file for file-like targets that don't exist yet" do
        assert_equal(:file, Resources.detect_type("/nonexistent/file.txt"))
      end
    end
  end
end
