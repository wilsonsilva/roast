# frozen_string_literal: true

module Roast
  class Initializers
    class << self
      def load_all
        # Project-specific initializers
        project_initializers = File.join(Dir.pwd, ".roast", "initializers")

        if Dir.exist?(project_initializers)
          $stderr.puts "Loading project initializers from #{project_initializers}"
          Dir.glob(File.join(project_initializers, "**/*.rb")).sort.each do |file|
            $stderr.puts "Loading initializer: #{file}"
            require file
          end
        end
      rescue => e
        Roast::Helpers::Logger.error("Error loading initializers: #{e.message}")
        # Don't fail the workflow if initializers can't be loaded
      end
    end
  end
end
