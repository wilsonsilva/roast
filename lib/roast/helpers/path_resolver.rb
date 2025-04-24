# frozen_string_literal: true

module Roast
  module Helpers
    # Utility class for resolving file paths with directory structure issues
    class PathResolver
      class << self
        # Intelligently resolves a path considering possible directory structure issues
        def resolve(path)
          # Store original path for logging if needed
          original_path = path

          # Early return if the path is nil or empty
          return path if path.nil? || path.empty?

          # First try standard path expansion
          expanded_path = File.expand_path(path)

          # Return early if the file exists at the expanded path
          return expanded_path if File.exist?(expanded_path)

          # Get current directory and possible project root paths
          current_dir = Dir.pwd
          possible_roots = [
            current_dir,
            File.expand_path(File.join(current_dir, "..")),
            File.expand_path(File.join(current_dir, "../..")),
            File.expand_path(File.join(current_dir, "../../..")),
            File.expand_path(File.join(current_dir, "../../../..")),
            File.expand_path(File.join(current_dir, "../../../../..")),
          ]

          # Check if path already contains duplicate directories
          path_parts = expanded_path.split(File::SEPARATOR).reject(&:empty?)
          duplicated_segments = path_parts.each_cons(2).select { |a, b| a == b }.map(&:first)

          if duplicated_segments.any?
            # Remove duplicated segments
            unique_parts = []
            path_parts.each_with_index do |part, i|
              next if i > 0 && part == path_parts[i - 1] && duplicated_segments.include?(part)

              unique_parts << part
            end

            # Join with leading slash if original path had one
            result = if original_path.start_with?("/")
              File.join("/", *unique_parts)
            else
              File.join(unique_parts)
            end

            # Return the deduplicated path if the file exists
            return result if File.exist?(result)
          end

          # Try relative path resolution from various possible roots
          relative_path = path.sub(%r{^\./}, "")
          possible_roots.each do |root|
            # Try the path as-is from this root
            candidate = File.join(root, relative_path)
            return candidate if File.exist?(candidate)

            # Try with a leading slash removed
            if relative_path.start_with?("/")
              candidate = File.join(root, relative_path.sub(%r{^/}, ""))
              return candidate if File.exist?(candidate)
            end
          end

          # Try extracting the path after a potential project root
          if expanded_path.include?("/src/") || expanded_path.include?("/lib/") || expanded_path.include?("/test/")
            # Potential project markers
            markers = ["/src/", "/lib/", "/test/", "/app/", "/config/"]
            markers.each do |marker|
              next unless expanded_path.include?(marker)

              # Get the part after the marker
              parts = expanded_path.split(marker, 2)
              next unless parts.size == 2

              marker_dir = marker.gsub("/", "")
              relative_from_marker = parts[1]

              # Try each possible root with this marker
              possible_roots.each do |root|
                candidate = File.join(root, marker_dir, relative_from_marker)
                return candidate if File.exist?(candidate)
              end
            end
          end

          # Default to the original expanded path if all else fails
          expanded_path
        end
      end
    end
  end
end
