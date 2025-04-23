# frozen_string_literal: true

require "spec_helper" # Assuming you have or will create a spec_helper

RSpec.describe(Roast) do
  it "has a version number" do
    expect(Roast::VERSION).not_to(be_nil)
  end

  xit "does something useful" do
    # Original test was `assert(false)`, replacing with a failing expectation
    # or mark as pending if desired: pending("add a real test")
    raise("implement me")
  end
end
