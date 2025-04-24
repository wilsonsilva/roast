# frozen_string_literal: true

require "test_helper"

module Roast
  module Support
    class PromptLoaderTest < Minitest::Test
      def setup
        @workflow = fixture_file("workflow/workflow.yml")
        @file = fixture_file("test.rb")
        @context = Roast::Workflow::ConfigurationParser.new(@workflow, files: [@file]).load_configuration
      end

      def test_loads_basic_prompt_file
        result = PromptLoader.load_prompt(@context, @file)
        assert_predicate(result, :starts_with?, "As a senior Ruby engineer and testing expert")
      end

      def test_loads_alternate_prompt_file_based_on_extension
        @file = fixture_file("test.ts")
        result = PromptLoader.load_prompt(@context, @file)
        assert_predicate(result, :starts_with?, "As a senior front-end engineer and testing expert")
      end

      def test_processes_erb_if_needed
        result = PromptLoader.load_prompt(@context, @file)
        assert_predicate(result, :include?, "class RoastTest < Minitest::Test")
      end
    end
  end
end
