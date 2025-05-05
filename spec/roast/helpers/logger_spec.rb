# frozen_string_literal: true

require "spec_helper"
require "roast/helpers/logger"
require "stringio"

RSpec.describe(Roast::Helpers::Logger) do
  let(:stringio) { StringIO.new }
  let(:logger) { described_class.new(stdout: stringio) }

  before do
    described_class.reset
  end

  describe "#initialize" do
    it "creates a default logger instance with INFO level" do
      expect(logger.logger).to(be_a(Logger))
      expect(logger.log_level).to(eq("INFO"))
      expect(logger.logger.level).to(eq(Logger::INFO))
    end

    it "accepts custom log level" do
      logger = described_class.new(stdout: stringio, log_level: "WARN")
      expect(logger.log_level).to(eq("WARN"))
      expect(logger.logger.level).to(eq(Logger::WARN))
    end

    it "raises error for invalid log level" do
      expect do
        described_class.new(log_level: "INVALID")
      end.to(raise_error(ArgumentError))
    end
  end

  describe "log level behavior" do
    it "filters messages based on log level" do
      logger = described_class.new(stdout: stringio, log_level: "WARN")

      # Debug and Info messages shouldn't appear at WARN level
      logger.debug("Debug message")
      logger.info("Info message")
      expect(stringio.string.strip).to(be_empty)

      # Warning messages should appear
      logger.warn("Warning message")
      expect(stringio.string).to(match(/Warning message/))
    end

    it "allows changing log level dynamically" do
      logger = described_class.new(stdout: stringio, log_level: "INFO")

      logger.info("Info message")
      logger.debug("Debug message")

      expect(stringio.string).to(match(/Info message/))
      expect(stringio.string).not_to(match(/Debug message/))

      # Change log level and see if debug messages now appear
      stringio.truncate(0)
      stringio.rewind

      logger.log_level = "DEBUG"
      logger.debug("New debug message")

      expect(stringio.string).to(match(/New debug message/))
    end
  end

  describe "class methods" do
    it "uses singleton instance for class methods" do
      described_class.instance_variable_set(:@instance, described_class.new(stdout: stringio))

      described_class.info("Class method test")
      expect(stringio.string).to(match(/Class method test/))
    end

    it "clears instance on reset" do
      old_instance = described_class.instance
      described_class.reset
      new_instance = described_class.instance

      expect(old_instance).not_to(eq(new_instance))
    end
  end

  describe "logging methods" do
    it "formats debug messages" do
      logger = described_class.new(stdout: stringio, log_level: "DEBUG")
      logger.debug("Debug message")
      expect(stringio.string).to(match(/DEBUG: Debug message/))
    end

    it "formats info messages without brackets" do
      logger.info("Info message")
      expect(stringio.string.strip).to(eq("Info message"))
    end

    it "formats info messages with brackets" do
      logger.info("[Bracketed message]")
      expect(stringio.string).to(match(/INFO: Bracketed message/))
    end

    it "formats warn messages" do
      logger.warn("Warning message")
      expect(stringio.string).to(match(/WARN: Warning message/))
    end

    it "formats error messages" do
      logger.error("Error message")
      expect(stringio.string).to(match(/ERROR: Error message/))
    end

    it "formats fatal messages" do
      logger.fatal("Fatal message")
      expect(stringio.string).to(match(/FATAL: Fatal message/))
    end
  end

  describe "message formatting" do
    it "handles string messages" do
      logger.info("Test message")
      expect(stringio.string.strip).to(eq("Test message"))
    end

    it "handles array messages" do
      logger.info(["First line", "Second line"])
      expect(stringio.string).to(match(/First line\nSecond line/))
    end

    it "handles single-element arrays" do
      logger.info(["Single string"])
      expect(stringio.string.strip).to(eq("Single string"))
    end

    it "handles non-string messages" do
      logger.info(123)
      expect(stringio.string.strip).to(eq("123"))
    end

    it "handles empty messages" do
      logger.info("")
      expect(stringio.string.strip).to(be_empty)
    end

    it "handles nil messages" do
      logger.info(nil)
      expect(stringio.string.strip).to(eq(""))
    end

    it "handles multiline messages" do
      long_message = "Line 1\n" + ("Very long line with lots of text " * 10) + "\nLine 3"
      logger.info(long_message)
      expect(stringio.string.strip).to(eq(long_message))
    end

    it "handles special characters" do
      special_chars = "Special characters: !@#$%^&*()_+<>?:\"{}|~`"
      logger.info(special_chars)
      expect(stringio.string.strip).to(eq(special_chars))
    end

    it "handles mixed array types" do
      logger.info(["String", 123, { key: "value" }])
      expect(stringio.string).to(match(/String\n123\n.*key.*value/))
    end
  end

  describe "thread safety" do
    it "handles concurrent logging" do
      threads = []
      10.times do |i|
        threads << Thread.new do
          logger.info("Thread #{i} message")
        end
      end

      threads.each(&:join)

      # Verify all thread messages were logged
      10.times do |i|
        expect(stringio.string).to(match(/Thread #{i} message/))
      end
    end
  end
end
