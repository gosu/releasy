require "relapse/builders/builder"

module Relapse
module Builders
  # General functionality for win32 builders.
  # @abstract
  # @attr icon [String] Optional filename of icon to show on executable/installer (.ico).
  class Win32Builder < Builder
    OCRA_COMMAND = "ocra"
    ICON_EXTENSION = ".ico"
    EXECUTABLE_TYPES = [:auto, :windows, :console]

    # @return [String] Extra options to send to Ocra (win32 outputs only).
    attr_accessor :ocra_parameters

    # @return [:auto, :windows, :console] Type of ruby to run executable with: :console means run with `ruby`, :windows means run with `rubyw`,  :auto means determine type from executable extension (.rb => :console or .rbw => :windows).
    attr_accessor :executable_type

    def valid_for_platform?; Relapse.win_platform?; end

    attr_reader :icon

    def icon=(icon)
      raise ConfigError, "icon must be a #{ICON_EXTENSION} file" unless File.extname(icon) == ICON_EXTENSION
      @icon = icon
    end

    def effective_executable_type
      if executable_type == :auto
        case File.extname(project.executable)
          when '.rbw'
            :windows
          when '.rb'
            :console
          else
            raise ConfigError, "Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console"
        end
      else
        executable_type
      end
    end

    protected
    def setup
      @icon = nil
      @ocra_parameters = ""
      @executable_type = :auto
    end

    protected
    def ocra_command
      command = defined?(Bundler) ? 'bundle exec ' : ''
      command += %[#{OCRA_COMMAND} "#{project.executable}" ]
      command += "--#{effective_executable_type} "
      command += "#{ocra_parameters} " if ocra_parameters
      command += %[--icon "#{icon}" ] if icon
      command += (project.files - [project.executable]).map {|f| %["#{f}"]}.join(" ")
      command
    end

    protected
    def create_link_files(dir)
      project.send(:links).each_pair do |url, title|
        create_link_file url, File.join(dir, title)
      end
    end

    protected
    def create_link_file(url, title)
      File.open("#{title}.url", "w") do |file|
        file.puts <<END
[InternetShortcut]
URL=#{url}
END
      end
    end
  end
end
end