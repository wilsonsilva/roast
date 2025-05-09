# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class StateRepositoryTest < ActiveSupport::TestCase
      def setup
        @repository = StateRepository.new
      end

      test "#save_state raises NotImplementedError" do
        assert_raises(NotImplementedError) do
          @repository.save_state(nil, nil, nil)
        end
      end

      test "#load_state_before_step raises NotImplementedError" do
        assert_raises(NotImplementedError) do
          @repository.load_state_before_step(nil, nil)
        end
      end

      test "#save_final_output raises NotImplementedError" do
        assert_raises(NotImplementedError) do
          @repository.save_final_output(nil, nil)
        end
      end
    end
  end
end
