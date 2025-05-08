# frozen_string_literal: true

require "spec_helper"

module Roast
  module Workflow
    RSpec.describe(StateRepository) do
      subject(:repository) { StateRepository.new }

      describe "#save_state" do
        it "raises NotImplementedError" do
          expect { repository.save_state(nil, nil, nil) }.to(raise_error(NotImplementedError))
        end
      end

      describe "#load_state_before_step" do
        it "raises NotImplementedError" do
          expect { repository.load_state_before_step(nil, nil) }.to(raise_error(NotImplementedError))
        end
      end

      describe "#save_final_output" do
        it "raises NotImplementedError" do
          expect { repository.save_final_output(nil, nil) }.to(raise_error(NotImplementedError))
        end
      end
    end
  end
end
