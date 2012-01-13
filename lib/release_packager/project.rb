%w[osx_app source win32_folder win32_installer win32_standalone].each do |builder|
  require "release_packager/builders/#{builder}"
end

module ReleasePackager
  ARCHIVE_FORMATS = {
      :"7z" => "7z a -mmt -t7z", # -mmt -> multithreaded compression. -mx0 -> don't compress
      :zip => "7z a -mmt -tzip",
      :tar_bz => "tar -jcvf" # 7z -tgzip (gzip), -ttar (tar), tbzip2 (bzip2)
  }

  DEFAULT_PACKAGE_FOLDER = "pkg"

  # Builder identifier => Builder class
  BUILDERS = {}
  Builders.constants.each do |constant|
    builder = Builders.const_get constant
    BUILDERS[builder.identifier] = builder if builder.ancestors.include? Builder
  end

  class Project
    include Rake::DSL

    attr_reader :underscored_name, :underscored_version, :license
    attr_accessor :name, :files, :version, :ocra_parameters, :executable, :icon, :output_path, :installer_group, :readme
    attr_writer :verbose

    def verbose?; @verbose; end

    # Must be text or rtf file, which will be shown to user who will be requested to accept it (win32 installer only).
    attr_writer :license

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
      @archives = []
      @outputs = []
      @links = {}
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

    def add_archive(type)
      raise ArgumentError, "Unsupported archive format #{type}" unless ARCHIVE_FORMATS.has_key? type
      @archives << type unless @archives.include? type

      type
    end

    # Add a type of output to produce. Must define at least one of these.
    def add_output(type)
      raise ArgumentError, "Unsupported output type #{type}" unless BUILDERS.has_key? type
      @outputs << type unless @outputs.include? type

      type
    end

    # Add a link file to be included in the win32 releases.
    def add_link(url, title)
      @links[url] = title

      url
    end

    # Generates all tasks required by the user. Automatically called at the end of the block, if #new is given a block.
    def generate_tasks
      raise "Must specify at least one output with #add_output before tasks can be generated" if @outputs.empty?

      build_outputs = []
      build_groups = Hash.new {|h, k| h[k] = [] }

      active_builders.each do |builder|
        builder.new self
        task_name = "build:#{builder.identifier.to_s.tr("_", ":")}"

        if builder.identifier.to_s =~ /_/
          build_groups[builder.group] << task_name
          build_outputs << "build:#{builder.group}"
        else
          build_outputs << task_name
        end
      end

      build_groups.each_pair do |group, tasks|
        desc "Build all #{group} outputs"
        task "build:#{group}" => tasks
      end

      desc "Build all outputs"
      task "build" => build_outputs

      generate_archive_tasks

      self
    end

    # The path to the folder to create. All variations will be based on extending this path.
    def folder_base
      File.join(@output_path, "#{underscored_name}#{version ? "_#{underscored_version}" : ""}")
    end

    protected
    # Only allow access to this from Builder
    def links; @links; end

    protected
    def active_builders
      BUILDERS.values.select {|b| @outputs.include? b.identifier }
    end

    # Generates the general tasks for compressing folders.
    protected
    def generate_archive_tasks
      win32_tasks = []
      top_level_tasks = []
      active_builders.each do |builder|
        task = builder.identifier.to_s.sub '_', ':'

        ARCHIVE_FORMATS.each_pair do |archive, command|
          next unless @archives.include? archive

          folder = "#{folder_base}_#{builder.folder_suffix}"
          package = "#{folder}.#{archive}"


          desc "Create #{package}"
          task "package:#{task}:#{archive}" => package
          file package => folder do
            archive(package, folder, command)
          end
        end

        desc "Package #{name} in all archive formats"
        task "package:#{task}" => @archives.map {|c| "package:#{task}:#{c}" }

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
    def archive(package, folder, command)
      puts "Compressing #{package}"
      rm package if File.exist? package
      cd @output_path do
        puts %x[#{command} "#{File.basename(package)}" "#{File.basename(folder)}"]
      end
    end
  end
end