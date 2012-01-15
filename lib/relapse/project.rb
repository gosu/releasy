%w[osx_app source win32_folder win32_installer win32_standalone].each do |builder|
  require "relapse/builders/#{builder}"
end

%w[seven_zip tar_bzip2 tar_gzip zip].each do |archiver|
  require "relapse/archivers/#{archiver}"
end

module Relapse
  DEFAULT_PACKAGE_FOLDER = "pkg"

  # Builder identifier => Builder class
  BUILDERS = {}
  Builders.constants.each do |constant|
    builder = Builders.const_get constant
    BUILDERS[builder.identifier] = builder if builder.ancestors.include? Builder
  end

  # Archiver identifier => Archiver class
  ARCHIVERS = {}
  Archivers.constants.each do |constant|
    archiver = Archivers.const_get constant
    ARCHIVERS[archiver.identifier] = archiver if archiver.ancestors.include? Archiver
  end

  # @attr underscored_name [String] Project name underscored (as used in file names), which will be derived from {#name}, but can be manually set.
  # @attr underscored_version [String] Version number, underscored so it can be used in file names, which will be derived from {#version}, but can be manually set.
  # @attr executable [String] Name of executable to run (defaults to 'bin/<underscored_name>')
  # @attr_reader folder_base [String] The path to the folder to create - All variations of output will be based on extending this path.
  class Project
    include Rake::DSL

    attr_writer :underscored_name, :underscored_version, :executable

    # @return [Boolean] Make the tasks give more detailed output.
    attr_writer :verbose
    # @return [String] Name of the application, such as "My Application".
    attr_accessor :name
    # @return [Array<String>] List of files to include in package.
    attr_accessor :files
    # @return [String] Version number as a string (for example, "1.2.0").
    attr_accessor :version
    # @return [String] Optional filename of icon to show on executable/installer (.ico).
    attr_accessor :icon
    # @return [String] Folder to output to (defaults to 'pkg/')
    attr_accessor :output_path
    # @return [String] File name of readme file - End user will have the option to view this after the win32 installer has installed, but must be .txt/.rtf.
    attr_accessor :readme
    # @return [String] Filename of license file - Must be text or rtf file, which will be shown to user who will be requested to accept it (win32 installer only).
    attr_accessor :license

    # Verbosity of the console output.
    # @return [Boolean] True to make the tasks output more information.
    def verbose?; @verbose; end

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

    def executable
      if @executable or underscored_name.nil?
        @executable
      else
        "bin/#{underscored_name}"
      end
    end

    # Can be used with or without a block to generate building and packaging tasks.
    #
    # @example
    #     # Using a block, the tasks are automatically generated when the block is closed.
    #     Project.new do |p|
    #       p.name = "My Application"
    #       p.add_output :source
    #     end
    #
    # @example
    #     # Without using a block.
    #     project = Project.new
    #     project.name = "My Application"
    #     project.add_output :source
    #     project.generate_tasks
    def initialize
      @archivers = []
      @builders = []
      @links = {}
      @files = []
      @osx_app_gems = []
      @output_path = DEFAULT_PACKAGE_FOLDER
      @verbose = true

      @name = @underscored_name = @underscored_version = @ocra_parameters = nil
      @version = @readme =  @executable = @license = @icon = nil
      @win32_installer_group = @osx_app_wrapper = @osx_app_url = nil

      if block_given?
        yield self
        generate_tasks
      end
    end

    # Add an archive type to be generated for each of your outputs.
    #
    # @param type [:7z, :tar_bz2, :tar_gz, :zip]
    # @return [Project] self
    def add_archive_format(type, &block)
      raise ArgumentError, "Unsupported archive format #{type}" unless ARCHIVERS.has_key? type
      raise RuntimeError, "Already have archive format #{type.inspect}" if @archivers.any? {|a| a.identifier == type }

      archiver = ARCHIVERS[type].new(self)
      @archivers << archiver

      yield archiver if block_given?

      archiver
    end

    # Add a type of output to produce. Must define at least one of these.
    #
    # @param [Symbol]
    # @return [Project] self
    def add_output(type, &block)
      raise ArgumentError, "Unsupported output type #{type}" unless BUILDERS.has_key? type
      raise RuntimeError, "Already have output #{type.inspect}" if @builders.any? {|b| b.identifier == type }

      builder = BUILDERS[type].new(self)
      @builders << builder

      yield builder if block_given?

      builder
    end

    # Add a link file to be included in the win32 releases. Will create the file _title.url_ for you.
    #
    # @param url [String] Url to link to.
    # @param title [String] Name of file to create.
    # @return [Project] self
    def add_link(url, title)
      @links[url] = title

      self
    end

    # Generates all tasks required by the user. Automatically called at the end of the block, if #new is given a block.
    def generate_tasks
      raise "Must specify at least one valid output for this OS with #add_output before tasks can be generated" if active_builders.empty?

      build_outputs = []
      build_groups = Hash.new {|h, k| h[k] = [] }

      active_builders.each do |builder|
        builder.generate_tasks
        task_name = "build:#{builder.identifier.to_s.tr("_", ":")}"

        if builder.identifier.to_s =~ /_/
          build_groups[builder.task_group] << task_name
          build_outputs << "build:#{builder.task_group}"
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


    def folder_base
      File.join(output_path, "#{underscored_name}#{version ? "_#{underscored_version}" : ""}")
    end

    protected
    # Only allow access to this from Builder
    # @return [Hash]
    def links; @links; end

    protected
    # @return [Array<Builder>]
    def active_builders
      @builders.find_all {|b| b.valid_for_platform? }
    end

    protected
    # @return [Array<Archiver>]
    def active_archivers
      @archivers
    end

    protected
    # Generates the general tasks for compressing folders.
    def generate_archive_tasks
      win32_tasks = []
      osx_tasks = []
      top_level_tasks = []
      active_builders.each do |builder|
        output_task = builder.identifier.to_s.sub '_', ':'

        active_archivers.each do |archiver|
          archiver.create_tasks output_task, builder.folder
        end

        desc "Package all #{builder.identifier}"
        task "package:#{output_task}" => active_archivers.map {|c| "package:#{output_task}:#{c.identifier}" }

        case output_task
          when /^win32:/
            win32_tasks << "package:#{output_task}"
            top_level_tasks << "package:win32" unless top_level_tasks.include? "package:win32"
          when /^osx:/
            osx_tasks << "package:#{output_task}"
            top_level_tasks << "package:osx" unless top_level_tasks.include? "package:osx"
          else
            top_level_tasks << "package:#{output_task}"
        end
      end

      unless win32_tasks.empty?
        desc "Package all win32"
        task "package:win32" => win32_tasks
      end

      unless osx_tasks.empty?
        desc "Package all osx"
        task "package:osx" => osx_tasks
      end

      desc "Package all"
      task "package" => top_level_tasks
    end
  end
end