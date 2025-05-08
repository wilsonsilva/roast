# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../../lib/roast/resources"

class RoastResourcesTest < Minitest::Test
  # .for tests
  def test_for_creates_file_resource_for_file_paths
    file_path = __FILE__
    resource = Roast::Resources.for(file_path)
    assert_kind_of(Roast::Resources::FileResource, resource)
  end

  def test_for_creates_directory_resource_for_directory_paths
    dir_path = File.dirname(__FILE__)
    resource = Roast::Resources.for(dir_path)
    assert_kind_of(Roast::Resources::DirectoryResource, resource)
  end

  def test_for_creates_url_resource_for_urls
    url = "https://example.com/api"
    resource = Roast::Resources.for(url)
    assert_kind_of(Roast::Resources::UrlResource, resource)
  end

  def test_for_creates_api_resource_for_fetch_api_style_configurations
    config = {
      url: "https://api.example.com/resource",
      options: {
        method: "GET",
        headers: {
          "Authorization": "Bearer token",
        },
      },
    }.to_json
    resource = Roast::Resources.for(config)
    assert_kind_of(Roast::Resources::ApiResource, resource)
  end

  def test_for_creates_none_resource_for_nil_target
    resource = Roast::Resources.for(nil)
    assert_kind_of(Roast::Resources::NoneResource, resource)
  end

  def test_for_creates_none_resource_for_empty_target
    resource = Roast::Resources.for("")
    assert_kind_of(Roast::Resources::NoneResource, resource)
  end

  # .detect_type tests
  def test_detect_type_returns_file_for_existing_files
    assert_equal(:file, Roast::Resources.detect_type(__FILE__))
  end

  def test_detect_type_returns_directory_for_existing_directories
    assert_equal(:directory, Roast::Resources.detect_type(File.dirname(__FILE__)))
  end

  def test_detect_type_returns_url_for_urls_with_http_https_scheme
    assert_equal(:url, Roast::Resources.detect_type("https://example.com"))
    assert_equal(:url, Roast::Resources.detect_type("http://example.com"))
    assert_equal(:url, Roast::Resources.detect_type("ftp://example.com"))
  end

  def test_detect_type_returns_api_for_fetch_api_style_json_configurations
    config = {
      url: "https://api.example.com/resource",
      options: {
        method: "GET",
      },
    }.to_json
    assert_equal(:api, Roast::Resources.detect_type(config))
  end

  def test_detect_type_returns_none_for_nil_target
    assert_equal(:none, Roast::Resources.detect_type(nil))
  end

  def test_detect_type_returns_none_for_empty_target
    assert_equal(:none, Roast::Resources.detect_type(""))
    assert_equal(:none, Roast::Resources.detect_type("  "))
  end

  def test_detect_type_returns_file_for_file_like_targets_that_do_not_exist_yet
    assert_equal(:file, Roast::Resources.detect_type("/nonexistent/file.txt"))
  end
end
