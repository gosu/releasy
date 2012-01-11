require "release_packager/osx"
require "release_packager/source"
require "release_packager/win32"


module ReleasePackager
  COMPRESSIONS = {
      :"7z" => "7z a -mmt -t7z", # -mmt -> multithreaded compression. -mx0 -> don't compress
      :zip => "7z a -mmt -tzip",
      :tar_bz => "tar -jcvf" # 7z -tgzip (gzip), -ttar (tar), tbzip2 (bzip2)
  }

  OUTPUTS = [:osx_app, :source, :win32_folder, :win32_installer, :win32_standalone]

  FOLDER_SUFFIXES = {
    :osx_app => "OSX",
    :source => SOURCE_SUFFIX,
    :win32_folder => "WIN32",
    :win32_installer => "WIN32_INSTALLER",
    :win32_standalone => "WIN32_EXE",
  }

  DEFAULT_PACKAGE_FOLDER = "pkg"

  class Project
    include Rake::DSL

    include Osx
    include Source
    include Win32

    attr_reader :underscored_name, :underscored_version
    attr_accessor :name, :files, :version, :ocra_parameters, :executable, :license, :icon, :output_path, :installer_group, :readme
    attr_writer :verbose

    def verbose?; @verbose; end

    # The name of the project used for creating file-names. It will either be generated from #name automatically, or can be set directly.
    def underscored_name
      if @underscored_name or @name.nil?
        @underscored_name
      else
        @name.strip.downcase.gsub(/[^a-z0-9_\- ]/i, '').split(/[\-_ ]+/).join("_")
      end
    end

    def underscored_version
      if @underscored_version or @version.nil?
        @underscored_version
      else
        @version.gsub(".", "_")
      end
    end

    # The name of the executable defaults to "bin/<underscored_name>", but can be set manually.
    def executable
      if @executable or underscored_name.nil?
        @executable
      else
        "bin/#{underscored_name}"
      end
    end

    def initialize
      @compressions = []
      @outputs = []
      @links= {}
      @files = []
      @output_path = DEFAULT_PACKAGE_FOLDER
      @verbose = true
      @readme = nil

      @name = @underscored_name = @underscored_version = @ocra_parameters = @version = @executable = @license = @icon = @installer_group = nil

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
    def add_link(url, title)
      @links[url] = title

      url
    end

    # The path to the folder to create. All variations will be based on extending this path.
    def folder_base
      File.join(@output_path, "#{underscored_name}#{version ? "_#{underscored_version}" : ""}")
    end

    # Generates all tasks required by the user. Automatically called at the end of the block, if #new is given a block.
    def generate_tasks
      raise "Must specify at least one output with #add_output before tasks can be generated" if @outputs.empty?

      build_groups = []

      if @outputs.include? :source
        build_source_folder
        build_groups << "source"
      end

      if @outputs.include? :osx_app
        build_osx_app
        build_groups << "osx"
      end

      build_win32_installer if @outputs.include? :win32_installer
      build_win32_standalone if @outputs.include? :win32_standalone
      build_win32_folder if @outputs.include? :win32_folder
      win32_outputs = @outputs.select {|o| o.to_s[0..4] == "win32" }

      if win32_outputs.any?
        build_groups << "win32"
        task "build:win32" => win32_outputs.map {|t| "build:#{t.to_s.split("_").join(":")}" }
      end

      task "build" => build_groups.map {|t| "build:#{t}" }

      generate_compression_tasks

      self
    end

    # Generates the general tasks for compressing folders.
    protected
    def generate_compression_tasks
      win32_tasks = []
      top_level_tasks = []
      FOLDER_SUFFIXES.each_pair do |name, output_suffix|
        next unless @outputs.include? name

        task = name.to_s.sub '_', ':'

        COMPRESSIONS.each_pair do |compression, command|
          next unless @compressions.include? compression

          folder = "#{folder_base}_#{output_suffix}"
          package = "#{folder}.#{compression}"


          desc "Create #{package}"
          task "package:#{task}:#{compression}" => package
          file package => folder do
            compress(package, folder, command)
          end
        end

        desc "Package #{name} in all compressions"
        task "package:#{task}" => @compressions.map {|c| "package:#{task}:#{c}" }

        if task.to_s =~ /win32/
          win32_tasks << "package:#{task}"
          top_level_tasks << "package:win32" unless top_level_tasks.include? "package:win32"
        else
          top_level_tasks << "package:#{task}"
        end
      end

      unless win32_tasks.empty?
        desc "Package all win32"
        task "package:win32" => win32_tasks
      end

      desc "Package all"
      task "package" => top_level_tasks
    end

    protected
    def compress(package, folder, command)
      puts "Compressing #{package}"
      rm package if File.exist? package
      cd @output_path do
        puts %x[#{command} "#{File.basename(package)}" "#{File.basename(folder)}"]
      end
    end

    # Copy a number of files into a folder, maintaining relative paths.
    protected
    def copy_files_relative(files, folder)
      files.each do |file|
        destination = File.join(folder, File.dirname(file))
        mkdir_p destination unless File.exists? destination
        cp file, destination
      end
    end
  end
end