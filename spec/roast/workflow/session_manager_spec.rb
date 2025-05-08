# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

module Roast
  module Workflow
    RSpec.describe(SessionManager) do
      let(:temp_dir) { Dir.mktmpdir }
      let(:file) { File.join(temp_dir, "test.rb") }
      let(:workflow_id) { 12345 }
      let(:session_name) { "test_workflow" }

      before do
        # Create a test file
        FileUtils.touch(file)
        allow(Dir).to(receive(:pwd).and_return(temp_dir))
        @manager = SessionManager.new
      end

      after do
        FileUtils.remove_entry(temp_dir) if temp_dir && File.exist?(temp_dir)
      end

      describe "#ensure_session_directory" do
        it "creates the directory structure" do
          session_dir = @manager.ensure_session_directory(workflow_id, session_name, file)

          expect(session_dir).to(be_truthy)
          expect(File.directory?(session_dir)).to(be(true))
          expect(File.exist?(File.join(File.dirname(session_dir), ".gitignore"))).to(be(true))
        end

        it "reuses existing session" do
          first_session_dir = @manager.ensure_session_directory(workflow_id, session_name, file)
          session_timestamp = @manager.session_timestamp(workflow_id)

          expect(session_timestamp).to(be_truthy)

          second_session_dir = @manager.ensure_session_directory(workflow_id, session_name, file)
          expect(first_session_dir).to(eq(second_session_dir))
        end
      end

      describe "#find_session_directory" do
        it "returns nil when no directory exists" do
          result = @manager.find_session_directory(session_name, file)
          expect(result).to(be_nil)
        end

        it "finds the latest session" do
          workflow_dir = expected_workflow_dir
          FileUtils.mkdir_p(workflow_dir)

          old_session = "20240101_010101_001"
          new_session = "20240101_010101_002"
          FileUtils.mkdir_p(File.join(workflow_dir, old_session))
          FileUtils.mkdir_p(File.join(workflow_dir, new_session))

          result = @manager.find_session_directory(session_name, file)
          expect(result).to(eq(File.join(workflow_dir, new_session)))
        end

        it "finds a specific timestamp when provided" do
          workflow_dir = expected_workflow_dir
          FileUtils.mkdir_p(workflow_dir)

          timestamp = "20240101_010101_001"
          session_dir = File.join(workflow_dir, timestamp)
          FileUtils.mkdir_p(session_dir)

          result = @manager.find_session_directory(session_name, file, timestamp)
          expect(result).to(eq(session_dir))
        end

        it "returns nil for nonexistent timestamp" do
          workflow_dir = expected_workflow_dir
          FileUtils.mkdir_p(workflow_dir)

          result = @manager.find_session_directory(session_name, file, "nonexistent")
          expect(result).to(be_nil)
        end
      end

      describe "#session_timestamp" do
        it "returns the timestamp" do
          @manager.set_session_timestamp(workflow_id, "20240101_010101_001")

          result = @manager.session_timestamp(workflow_id)
          expect(result).to(eq("20240101_010101_001"))
        end
      end

      describe "#create_new_session" do
        it "sets a timestamp" do
          result = @manager.create_new_session(workflow_id)

          expect(result).to(match(/^\d{8}_\d{6}_\d{3}$/))
          expect(@manager.session_timestamp(workflow_id)).to(eq(result))
        end
      end

      private

      def expected_workflow_dir
        workflow_dir_name = session_name.parameterize.underscore
        file_id = Digest::MD5.hexdigest(file)
        file_basename = File.basename(file).parameterize.underscore
        human_readable_id = "#{file_basename}_#{file_id[0..7]}"
        File.join(temp_dir, ".roast", "sessions", workflow_dir_name, human_readable_id)
      end
    end
  end
end
