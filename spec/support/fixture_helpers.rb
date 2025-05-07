# frozen_string_literal: true

module FixtureHelpers
  def fixture_file(filename)
    File.join(File.dirname(__FILE__), "..", "fixtures", filename)
  end

  def fixture_file_path(filename)
    File.expand_path(fixture_file(filename))
  end

  def fixture_file_content(filename)
    File.read(fixture_file(filename))
  end
end
