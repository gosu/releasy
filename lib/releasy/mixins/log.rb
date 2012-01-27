module Releasy::Mixins::Log
  class << self
    LOG_LEVELS = [:silent, :quiet, :verbose]
    DEFAULT_LOG_LEVEL = :quiet

    def log_level; @log_level ||= DEFAULT_LOG_LEVEL; end
    def log_level=(level)
      raise ArgumentError, "Bad log_level: #{level.inspect}" unless LOG_LEVELS.include? level
      @log_level = level
    end
  end

  protected
  # Current level of logging. This affects ALL objects that are logging!
  def log_level; Releasy::Mixins::Log.log_level; end

  protected
  # Options for fileutils commands, based on log_level.
  def fileutils_options
    { :verbose => log_level == :verbose }
  end

  protected
  # Heading message shown unless :silent
  def heading(str)
    puts "=== #{str}" unless log_level == :silent
  end

  protected
  # Heading message shown if :verbose
  def info(str)
    puts str if log_level == :verbose
  end

  protected
  # Warning message shown unless :silent
  def warn(str)
    puts "=== WARNING: #{str}" unless log_level == :silent
  end

  protected
  # Error message always shown.
  def error(str)
    puts "=== ERROR: #{str}"
  end
end