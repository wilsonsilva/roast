# frozen_string_literal: true

require "minitest/autorun"
require "json-schema"
require "yaml"
require "json"
require "roast/workflow/validator"

# Define Roast::ROOT for test environment
module Roast
  ROOT = Dir.pwd unless const_defined?(:ROOT)
end

# Helper to load fixture files (assumes test/fixtures directory)
def fixture_file_content(filename)
  path = File.join(Dir.pwd, "test/fixtures", filename)
  File.read(path)
end

module Roast
  module Workflow
    class ValidatorTest < Minitest::Test
      def setup
        @schema_path = File.join(Dir.pwd, "schema/workflow.json")
        @valid_yaml = fixture_file_content("valid_workflow.yml")
        @invalid_yaml = fixture_file_content("invalid_workflow.yml")
      end

      # #initialize
      def test_initialize_with_valid_yaml
        assert_silent do
          Roast::Workflow::Validator.new(@valid_yaml)
        end
      end

      def test_initialize_raises_error_with_invalid_yaml
        yaml = "name: - test"
        assert_raises(Psych::SyntaxError) do
          Roast::Workflow::Validator.new(yaml)
        end
      end

      # #valid?
      def test_valid_returns_true_with_valid_yaml_matching_schema
        validator = Roast::Workflow::Validator.new(@valid_yaml)
        assert_equal(true, validator.valid?)
      end

      def test_valid_returns_false_with_valid_yaml_not_matching_schema
        validator = Roast::Workflow::Validator.new(@invalid_yaml)
        assert_equal(false, validator.valid?)
      end

      def test_valid_returns_false_with_empty_yaml
        yaml = ""
        validator = Roast::Workflow::Validator.new(yaml)
        assert_equal(false, validator.valid?)
      end

      # #errors
      def test_errors_returns_empty_array_when_yaml_is_valid
        validator = Roast::Workflow::Validator.new(@valid_yaml)
        validator.valid?
        assert_empty(validator.errors)
      end

      def test_errors_returns_validation_errors_when_yaml_does_not_match_schema
        validator = Roast::Workflow::Validator.new(@invalid_yaml)
        validator.valid?
        refute_empty(validator.errors)
        assert_includes(validator.errors.first, "steps")
      end
    end
  end
end
