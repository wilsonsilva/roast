# frozen_string_literal: true

require "spec_helper" # Assuming you have or will create a spec_helper

RSpec.describe(Roast) do
  it "has a version number" do
    expect(Roast::VERSION).not_to(be_nil)
  end
end
