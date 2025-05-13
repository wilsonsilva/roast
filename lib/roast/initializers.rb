# frozen_string_literal: true

module Roast
  class Initializers
    class << self
      def initializers_path
        File.join(Dir.pwd, ".roast", "initializers")
      end

      def load_all
        project_initializers = Roast::Initializers.initializers_path
        return unless Dir.exist?(project_initializers)

        $stderr.puts "Loading project initializers from #{project_initializers}"
        pattern = File.join(project_initializers, "**/*.rb")
        Dir.glob(pattern).sort.each do |file|
          $stderr.puts "Loading initializer: #{file}"
          require file
        end
      rescue => e
        Roast::Helpers::Logger.error("Error loading initializers: #{e.message}")
        # Don't fail the workflow if initializers can't be loaded
      end
    end
  end
end
