require "relapse/builders/builder"

module Relapse
module Builders
  # General functionality for Windows builders.
  # @abstract
  # @attr icon [String] Optional filename of icon to show on executable/installer (.ico).
  class WindowsBuilder < Builder
    EXECUTABLE_TYPES = [:auto, :windows, :console]

    # @return [:auto, :windows, :console] Type of ruby to run executable with: :console means run with `ruby`, :windows means run with `rubyw`,  :auto means determine type from executable extension (.rb => :console or .rbw => :windows).
    attr_accessor :executable_type

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
      @executable_type = :auto
      super
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