# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About the codebase
- This is a Ruby gem called Roast. Its purpose is to run AI workflows defined in a YAML file.

## Commands

- Build: `bundle exec rake build`
- Test all: `bundle exec rspec`
- Run single test: `bundle exec rspec spec/path/to/test_file.rb`
- Lint: `bundle exec rubocop -A`
- Default (tests + lint): `bundle exec rake`

## Tech stack
- `cli-kit` and `cli-ui` for the CLI tool
- Testing: Use Rspec, VCR for HTTP mocking, test files named with `_spec.rb` suffix

## Code Style Guidelines

- Naming: snake_case for variables/methods, CamelCase for classes/modules, ALL_CAPS for constants
- Module structure: Use nested modules under the `Roast` namespace
- Command pattern: Commands implement a `call` method and class-level `help` method
- Error handling: Use custom exception classes and structured error handling
- Errors that should stop the program execution should `raise(CLI::Kit::Abort, "Error message")`
- Documentation: Include method/class documentation with examples when appropriate
- Dependencies: Prefer existing gems in the Gemfile before adding new ones
- Define class methods inside `class << self; end` declarations.
- Add runtime dependencies to `roast.gemspec`.
- Add development dependencies to `Gemfile`.