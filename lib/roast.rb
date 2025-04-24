# frozen_string_literal: true

require "raix"
require "thor"
require "roast/version"
require "roast/tools"
require "roast/helpers"
require "roast/workflow"
module Roast
  ROOT = File.expand_path("../..", __FILE__)

  class CLI < Thor
    desc "execute [PATH] [FILES_TO_RUN_WORKFLOW_ON]", "Roasts the workflow at PATH (Optional: specify files to run workflow on)"
    option :concise, type: :boolean, aliases: "-c", desc: "Optional flag for use in output templates"
    option :subject, type: :string, aliases: "-s", desc: "Path to file containing the subject of the workflow (optional, assigned to workflow.subject)"
    option :output, type: :string, aliases: "-o", desc: "Save results to a file"
    option :verbose, type: :boolean, aliases: "-v", desc: "Show output from all steps as they are executed"
    def execute(*paths)
      raise Thor::Error, "Workflow path is required" if paths.empty?

      puts "Loading #{paths.first}..."

      workflow_path, *files = paths.map { |path| File.expand_path(path, ROOT) }
      raise Thor::Error, "Workflow file not found" unless File.exist?(workflow_path)

      if options[:subject] && !File.exist?(options[:subject])
        raise Thor::Error, "Subject file does not exist: #{options[:subject]}"
      end

      Roast::Workflow::ConfigurationParser.new(workflow_path, files, options).begin!
    end

    class << self
      def exit_on_failure?
        true
      end
    end
  end
end
