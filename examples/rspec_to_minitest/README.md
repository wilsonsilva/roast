# RSpec to Minitest Migration Workflow

This workflow demonstrates how to automate the migration of RSpec tests to their Minitest equivalents, following a structured approach to ensure proper test coverage and functionality.

## Workflow Overview

The workflow consists of three main steps:

1. **Analyze Spec**: Understand the purpose and structure of the RSpec test, including its dependencies and testing patterns.
2. **Create Minitest**: Generate a new Minitest file with equivalent test coverage and assertions.
3. **Run and Improve**: Execute the Minitest file and iteratively improve it until all tests pass.

## Prerequisites

- Ruby environment with both RSpec and Minitest gems installed
- Access to the original codebase being tested
- Ability to run tests in the target environment

## Usage

To use this workflow:

1. Configure the target pattern in `workflow.yml` to match the RSpec files you want to convert (or pass in via CLI --target option):
   ```yaml
   target: "path/to/specs/**/*_spec.rb"
   ```

2. Run the workflow with:
   ```
   roast execute examples/rspec_to_minitest/workflow.yml
   ```

3. Review the generated Minitest files and ensure they're correctly placed in your test directory.

## Implementation Details

The workflow leverages the following tools:

- Standard file operations (read/write)
- Code search capabilities to find related files
- Command execution to run tests
- CodingAgent for iterative improvements using AI-powered coding assistance

## Required Tool: CodingAgent

This workflow introduces a new tool called `CodingAgent` which leverages Claude Code to perform code-related tasks:

1. Running tests
2. Analyzing errors and failures
3. Making iterative improvements to code

The CodingAgent tool is implemented in `lib/roast/tools/coding_agent.rb`.

## Conversion Mappings

The workflow handles these common RSpec to Minitest conversions:

| RSpec Feature | Minitest Equivalent |
|---------------|---------------------|
| `describe/context` | Test class |
| `it` blocks | `test_*` methods |
| `before/after` | `setup/teardown` methods |
| `let/let!` | Instance variables or helper methods |
| `expect(x).to eq(y)` | `assert_equal y, x` |
| `expect(x).to be_truthy` | `assert x` |
| `expect(x).to be_falsey` | `refute x` |
| `expect { ... }.to raise_error` | `assert_raises { ... }` |
| Mocks/doubles | Minitest mocking or Mocha |
