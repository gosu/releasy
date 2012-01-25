require "releasy/builders/windows_builder"

module Releasy
module Builders
  # Functionality for a {WindowsBuilder} that use Ocra and runs on Windows.
  # @attr icon [String] Optional filename of icon to show on executable/installer (.ico).
  # @abstract
  class OcraBuilder < WindowsBuilder
    OCRA_COMMAND = "ocra"
    ICON_EXTENSION = ".ico"

    # @return [String] Extra options to send to Ocra (Windows outputs only).
    attr_accessor :ocra_parameters

    def valid_for_platform?; Releasy.win_platform?; end

    attr_reader :icon
    def icon=(icon)
      raise ArgumentError, "icon must be a #{ICON_EXTENSION} file" unless File.extname(icon) == ICON_EXTENSION
      @icon = icon
    end

    protected
    def setup
      @icon = nil
      @ocra_parameters = ""
      super
    end

    protected
    def ocra_command
      command = defined?(Bundler) ? 'bundle exec ' : ''
      command += %[#{OCRA_COMMAND} "#{project.executable}" ]
      command += "--#{effective_executable_type} "
      command += "--no-enc " if encoding_excluded?
      command += "#{ocra_parameters} " if ocra_parameters
      command += %[--icon "#{icon}" ] if icon
      command += (project.files - [project.executable]).map {|f| %["#{f}"]}.join(" ")
      command
    end
  end
end
end