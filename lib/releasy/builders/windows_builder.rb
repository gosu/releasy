require "releasy/builders/builder"
require "releasy/mixins/can_exclude_encoding"

module Releasy
module Builders
  # General functionality for Windows builders.
  # @abstract
  # @attr icon [String] Optional filename of icon to show on executable/installer (.ico).
  class WindowsBuilder < Builder
    include Mixins::CanExcludeEncoding

    EXECUTABLE_TYPES = [:auto, :windows, :console]

    # @return [:auto, :windows, :console] Type of ruby to run executable with. :console means run with 'ruby.exe', :windows means run with 'rubyw.exe',  :auto means determine type from executable extension (.rb => :console or .rbw => :windows).
    attr_accessor :executable_type

    # Executable type, resolving :auto if possible.
    # @return [:windows, :console]
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