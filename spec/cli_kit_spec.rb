# frozen_string_literal: true

require "spec_helper"

# NOTE: The original file was ExampleTest nested under Roast.
# Adjust the describe block if this nesting is important.
RSpec.describe("CLI::Kit integration") do
  # Include the helper module provided by cli-kit
  include CLI::Kit::Support::TestHelper

  it "allows faking system calls and capturing output" do
    # Use the fake method from the included helper
    CLI::Kit::System.fake("ls -al", stdout: "a\nb", success: true)

    # Capture the output using capture2
    out, = CLI::Kit::System.capture2("ls", "-al")

    # Use RSpec expectation for equality
    expect(out.split("\n")).to(eq(["a", "b"]))

    # Check that all faked commands were run. This helper might raise an error
    # if commands were faked but not called. Wrapping in `expect { ... }.not_to raise_error`
    # is one way to assert this in RSpec.
    expect { assert_all_commands_run }.not_to(raise_error)
  end
end
