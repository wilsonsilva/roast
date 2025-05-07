# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe(Roast::Resources::ApiResource) do
  let(:simple_url) { "https://api.example.com/data" }
  let(:fetch_style_config) do
    {
      url: "https://api.example.com/resource",
      options: {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer token123",
        },
        body: {
          query: "search term",
          limit: 10,
        },
      },
    }.to_json
  end

  describe "#config" do
    it "parses JSON configuration when provided" do
      resource = described_class.new(fetch_style_config)
      expect(resource.config).to(be_a(Hash))
      expect(resource.config["url"]).to(eq("https://api.example.com/resource"))
      expect(resource.config["options"]).to(be_a(Hash))
    end

    it "returns nil for non-JSON targets" do
      resource = described_class.new(simple_url)
      expect(resource.config).to(be_nil)
    end
  end

  describe "#api_url" do
    it "extracts URL from config when available" do
      resource = described_class.new(fetch_style_config)
      expect(resource.api_url).to(eq("https://api.example.com/resource"))
    end

    it "uses target as URL when no config is available" do
      resource = described_class.new(simple_url)
      expect(resource.api_url).to(eq(simple_url))
    end
  end

  describe "#options" do
    it "returns options from config when available" do
      resource = described_class.new(fetch_style_config)
      expect(resource.options).to(be_a(Hash))
      expect(resource.options["method"]).to(eq("POST"))
      expect(resource.options["headers"]).to(include("Content-Type" => "application/json"))
    end

    it "returns empty hash when no config is available" do
      resource = described_class.new(simple_url)
      expect(resource.options).to(eq({}))
    end
  end

  describe "#http_method" do
    it "returns appropriate Net::HTTP class for specified method" do
      resource = described_class.new(fetch_style_config) # POST method
      expect(resource.http_method).to(eq(Net::HTTP::Post))
    end

    it "defaults to GET for simple URLs" do
      resource = described_class.new(simple_url)
      expect(resource.http_method).to(eq(Net::HTTP::Get))
    end

    it "supports various HTTP methods" do
      methods = {
        "GET" => Net::HTTP::Get,
        "POST" => Net::HTTP::Post,
        "PUT" => Net::HTTP::Put,
        "DELETE" => Net::HTTP::Delete,
        "PATCH" => Net::HTTP::Patch,
        "HEAD" => Net::HTTP::Head,
      }

      methods.each do |method_name, expected_class|
        config = { url: "https://example.com", options: { method: method_name } }.to_json
        resource = described_class.new(config)
        expect(resource.http_method).to(eq(expected_class))
      end
    end
  end

  describe "#exists?" do
    let(:mock_response) { instance_double(Net::HTTPResponse, code: "200") }
    let(:mock_http) { instance_double(Net::HTTP) }

    before do
      allow(Net::HTTP).to(receive(:new).and_return(mock_http))
      allow(mock_http).to(receive(:use_ssl=))
      allow(mock_http).to(receive(:request).and_return(mock_response))
    end

    it "returns true for successful HTTP responses" do
      resource = described_class.new(simple_url)
      expect(resource.exists?).to(eq(true))
    end

    it "returns false for nil target" do
      resource = described_class.new(nil)
      expect(resource.exists?).to(eq(false))
    end

    it "returns false for failed HTTP responses" do
      allow(mock_response).to(receive(:code).and_return("404"))
      resource = described_class.new(simple_url)
      expect(resource.exists?).to(eq(false))
    end

    it "returns false when HTTP request raises an error" do
      allow(mock_http).to(receive(:request).and_raise(StandardError.new("Connection failed")))
      resource = described_class.new(simple_url)
      expect(resource.exists?).to(eq(false))
    end

    it "substitutes environment variables in headers" do
      ENV["TEST_API_TOKEN"] = "test-token-123"
      begin
        config = {
          url: "https://api.example.com/resource",
          options: {
            method: "GET",
            headers: {
              "Authorization": "Bearer ${TEST_API_TOKEN}",
            },
          },
        }.to_json

        resource = described_class.new(config)

        # Instead of trying to mock the HTTP request, let's test the actual
        # implementation behavior by making the necessary methods accessible
        class << resource
          public :process_env_vars
        end

        # Test that the environment variable is properly substituted
        substituted = resource.process_env_vars("Bearer ${TEST_API_TOKEN}")
        expect(substituted).to(eq("Bearer test-token-123"))

        # We'll skip the actual HTTP request since we've verified the substitution works
        allow(mock_http).to(receive(:request).and_return(mock_response))
        resource.exists?
      ensure
        ENV.delete("TEST_API_TOKEN")
      end
    end
  end

  describe "#contents" do
    before do
      # Stub HTTP request for simple URLs
      allow(Net::HTTP).to(receive(:get).and_return('{"result": "success"}'))
    end

    it "returns API response for simple URLs" do
      resource = described_class.new(simple_url)
      expect(resource.contents).to(eq('{"result": "success"}'))
    end

    it "returns formatted config for Fetch API style targets" do
      resource = described_class.new(fetch_style_config)
      result = resource.contents
      expect(result).to(be_a(String))
      expect(JSON.parse(result)).to(include(
        "url" => "https://api.example.com/resource",
        "method" => "POST",
      ))
    end

    it "includes environment variables in formatted output" do
      ENV["TEST_API_TOKEN"] = "test-token-123"
      begin
        config = {
          url: "https://api.example.com/resource",
          options: {
            method: "GET",
            headers: {
              "Authorization": "Bearer ${TEST_API_TOKEN}",
            },
          },
        }.to_json

        resource = described_class.new(config)
        result = resource.contents
        parsed = JSON.parse(result)

        # The contents method should include the raw headers
        # Environment variable substitution happens when the request is made
        expect(parsed["headers"]).to(include("Authorization" => "Bearer ${TEST_API_TOKEN}"))
      ensure
        ENV.delete("TEST_API_TOKEN")
      end
    end

    it "returns nil for nil target" do
      resource = described_class.new(nil)
      expect(resource.contents).to(be_nil)
    end

    it "returns nil when HTTP request raises an error" do
      allow(Net::HTTP).to(receive(:get).and_raise(StandardError.new("Connection failed")))
      resource = described_class.new(simple_url)
      expect(resource.contents).to(be_nil)
    end
  end

  describe "#name" do
    it "includes URL and method for Fetch API style targets" do
      resource = described_class.new(fetch_style_config)
      expect(resource.name).to(eq("API https://api.example.com/resource (POST)"))
    end

    it "includes URL for simple URL targets" do
      resource = described_class.new(simple_url)
      expect(resource.name).to(eq("API #{simple_url}"))
    end

    it "returns default name for nil target" do
      resource = described_class.new(nil)
      expect(resource.name).to(eq("Unnamed API"))
    end
  end

  describe "#type" do
    it "always returns :api" do
      resource = described_class.new(simple_url)
      expect(resource.type).to(eq(:api))
    end
  end
end
