# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "rake/testtask"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
end

Rake::TestTask.new(:minitest) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task test: [:spec, :minitest]

RuboCop::RakeTask.new do |task|
  task.options = ["--autocorrect"]
end

task default: [:test, :rubocop]
