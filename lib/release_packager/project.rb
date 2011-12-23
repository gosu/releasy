require "release_packager/osx"
require "release_packager/source"
require "release_packager/win32"


module ReleasePackager
  COMPRESSIONS = {
      :"7z" => "7z a",
      :zip => "7z a -tzip",
      :tar_bz => "tar -jcvf"
  }

  OUTPUTS = [:osx_app, :source, :win32_exe, :win32_installer, :win32_standalone]

  DEFAULT_PACKAGE_FOLDER = "pkg"

  class Project
    include Osx
    include Source
    include Win32

    attr_reader :id
    attr_accessor :name, :files, :name, :version, :ocra_parameters, :execute, :license, :icon, :output_path

    def initialize(id)
      @id = id
      @name = id.to_s.split(/-|_/).map(&:capitalize).join(" ")
      @compressions = []
      @outputs = []
      @links= {}
      @files = []
      @output_path = DEFAULT_PACKAGE_FOLDER

      @ocra_parameters = @version = @execute = @license = @icon = nil

      if block_given?
        yield self
        generate_tasks
      end
    end

    def add_compression(type)
      raise ArgumentError, "Unsupported compression type #{type}" unless COMPRESSIONS.has_key? type
      @compressions << type unless @compressions.include? type

      type
    end

    # Add a type of output to produce. Must define at least one of these.
    def add_output(type)
      raise ArgumentError, "Unsupported output type #{type}" unless OUTPUTS.include? type
      @outputs << type unless @outputs.include? type

      type
    end

    # Add a link file to be included in the win32 releases.
    def add_link(url, description)
      @links[url] = description

      url
    end

    # The path to the folder to create. All variations will be based on extending this path.
    def folder_base
      File.join(@output_path, "#{id}#{version ? "_#{version.tr(".", "_")}" : ""}")
    end

    # Generates all tasks required by the user. Automatically called at the end of the block, if #new is given a block.
    def generate_tasks
      raise "Must specify at least one output with #add_output before tasks can be generated" if @outputs.empty?

      create_source_folder if @outputs.include? :source

      generate_compression_tasks
    end

    # Generates the general tasks for compressing folders.
    protected
    def generate_compression_tasks
      {
          :source => SOURCE_SUFFIX,
          :win32_standalone => "WIN32_EXE",
          :win32_exe => "WIN32",
          :win32_installer => "WIN32_INSTALLER",
      }.each_pair do |name, output_suffix|
        next unless @outputs.include? name

        COMPRESSIONS.each_pair do |compression, command|
          next unless @compressions.include? compression

          folder = "#{folder_base}_#{output_suffix}"
          package = "#{folder}.#{compression}"

          desc "Create #{package}"
          task "release:#{name}:#{compression}" => package
          file package => folder do
            compress(package, folder, command)
          end
        end

        desc "Release #{name} in all compressions"
        task "release:#{name}" => @compressions.map {|c| "release:#{name}:#{c}" }
      end
    end

    protected
    def compress(package, folder, command)
      puts "Compressing #{package}"
      rm package if File.exist? package
      cd @output do
        puts File.basename(package)
        puts %x[#{command} "#{File.basename(package)}" "#{File.basename(folder)}"]
      end
    end
  end
end