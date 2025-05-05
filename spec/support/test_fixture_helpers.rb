# frozen_string_literal: true

module TestFixtureHelpers
  def test_fixture_file(filename)
    File.join(Dir.pwd, "test/fixtures/files", filename)
  end

  def test_fixture_file_content(filename)
    File.read(test_fixture_file(filename))
  end
end
