# frozen_string_literal: true

require "minitest/autorun"
require "roast/helpers/logger"
require "stringio"

module Roast
  module Helpers
    class LoggerTest < Minitest::Test
      # Reset global logger instance before each test
      def setup
        Logger.reset
      end

      describe "initialization" do
        def test_default_initialization
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          assert_instance_of(::Logger, logger.logger)
          assert_equal("INFO", logger.log_level)
          assert_equal(::Logger::INFO, logger.logger.level)
        end

        def test_custom_log_level
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio, log_level: "WARN")

          assert_equal("WARN", logger.log_level)
          assert_equal(::Logger::WARN, logger.logger.level)
        end

        def test_invalid_log_level
          assert_raises(ArgumentError) do
            Logger.new(log_level: "INVALID")
          end
        end
      end

      describe "log level behavior" do
        def test_log_level_filtering
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio, log_level: "WARN")

          # Debug and Info messages shouldn't appear at WARN level
          logger.debug("Debug message")
          logger.info("Info message")
          assert_empty(stringio.string.strip)

          # Warning messages should appear
          logger.warn("Warning message")
          assert_match(/Warning message/, stringio.string)
        end

        def test_changing_log_level
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio, log_level: "INFO")

          logger.info("Info message")
          logger.debug("Debug message")

          assert_match(/Info message/, stringio.string)
          refute_match(/Debug message/, stringio.string)

          # Change log level and see if debug messages now appear
          stringio.truncate(0)
          stringio.rewind

          logger.log_level = "DEBUG"
          logger.debug("New debug message")

          assert_match(/New debug message/, stringio.string)
        end
      end

      describe "instance vs class methods" do
        def test_class_methods_use_singleton
          stringio = StringIO.new
          Logger.instance_variable_set(:@instance, Logger.new(stdout: stringio))

          Logger.info("Class method test")
          assert_match(/Class method test/, stringio.string)
        end

        def test_reset_clears_instance
          old_instance = Logger.instance
          Logger.reset
          new_instance = Logger.instance

          refute_equal(old_instance, new_instance)
        end
      end

      describe "logging methods" do
        def test_debug_method
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio, log_level: "DEBUG")

          logger.debug("Debug message")
          assert_match(/DEBUG: Debug message/, stringio.string)
        end

        def test_info_method_standard_format
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info("Info message")
          assert_equal("Info message", stringio.string.strip)
        end

        def test_info_method_with_brackets
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info("[Bracketed message]")
          assert_match(/INFO: Bracketed message/, stringio.string)
        end

        def test_warn_method
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.warn("Warning message")
          assert_match(/WARN: Warning message/, stringio.string)
        end

        def test_error_method
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.error("Error message")
          assert_match(/ERROR: Error message/, stringio.string)
        end

        def test_fatal_method
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.fatal("Fatal message")
          assert_match(/FATAL: Fatal message/, stringio.string)
        end
      end

      describe "message formatting" do
        def test_string_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info("Test message")
          assert_equal("Test message", stringio.string.strip)
        end

        def test_array_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info(["First line", "Second line"])
          assert_match(/First line\nSecond line/, stringio.string)
        end

        def test_array_with_single_string
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info(["Single string"])
          assert_equal("Single string", stringio.string.strip)
        end

        def test_non_string_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info(123)
          assert_equal("123", stringio.string.strip)
        end

        def test_empty_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info("")
          assert_empty(stringio.string.strip)
        end

        def test_nil_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info(nil)
          assert_equal("", stringio.string.strip)
        end

        def test_multiline_message
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          long_message = "Line 1\n" + ("Very long line with lots of text " * 10) + "\nLine 3"
          logger.info(long_message)
          assert_equal(long_message, stringio.string.strip)
        end

        def test_special_characters
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          special_chars = "Special characters: !@#$%^&*()_+<>?:\"{}|~`"
          logger.info(special_chars)
          assert_equal(special_chars, stringio.string.strip)
        end

        def test_mixed_array_types
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          logger.info(["String", 123, { key: "value" }])
          assert_match(/String\n123\n.*key.*value/, stringio.string)
        end
      end

      describe "thread safety" do
        def test_concurrent_logging
          stringio = StringIO.new
          logger = Logger.new(stdout: stringio)

          threads = []
          10.times do |i|
            threads << Thread.new do
              logger.info("Thread #{i} message")
            end
          end

          threads.each(&:join)

          # Verify all thread messages were logged
          10.times do |i|
            assert_match(/Thread #{i} message/, stringio.string)
          end
        end
      end
    end
  end
end
