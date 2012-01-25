require 'relapse/dsl_wrapper'
require 'relapse/builders'
require 'relapse/archivers'
require "relapse/mixins/has_archivers"

module Relapse
  # A description of the Ruby application that is being build for release and what packages to make from it.
  #
  # @attr underscored_name [String] Project name underscored (as used in file names), which will be derived from {#name}, but can be manually set.
  # @attr underscored_version [String] Version number, underscored so it can be used in file names, which will be derived from {#version}, but can be manually set.
  # @attr executable [String] Name of executable to run (defaults to 'bin/<underscored_name>')
  # @attr_reader folder_base [String] The path to the folders to create. All variations of output will be based on extending this path.
  # @attr files [Rake::FileList] List of files to include in package.
  # @attr exposed_files [Rake::FileList] Files which should always be copied into the archive folder root, so they are always visible to the user. e.g readme, change-log and/or license files.
  class Project
    include Rake::DSL
    include Mixins::HasArchivers

    DEFAULT_PACKAGE_FOLDER = "pkg"

    attr_writer :underscored_name, :underscored_version, :executable

    # @return [String] Name of the application, such as "My Application".
    attr_accessor :name
    # @return [String] Version number as a string (for example, "1.2.0").
    attr_accessor :version
    # @return [String] Folder to output to (defaults to 'pkg/')
    attr_accessor :output_path

    # Make the tasks give more detailed output.
    # @return [nil]
    def verbose; @verbose = true; nil; end
    # Make the tasks give less detailed output.
    # @return [nil]
    def quiet; @verbose = false; nil; end
    def verbose?; @verbose; end

    # Create MD5 hashes for created archives.
    # @return [nil]
    def create_md5s; @create_md5s = true; nil; end
    def create_md5s?; @create_md5s; end
    protected :create_md5s?

    # Verbosity of the console output.
    # @return [Boolean] True to make the tasks output more information.
    def verbose?; @verbose; end

    def exposed_files; @exposed_files; end
    def exposed_files=(files); @exposed_files = Rake::FileList.new files; end

    def files; @files; end
    def files=(files); @files = Rake::FileList.new files; end

    # @return [String]
    def to_s; "<#{self.class}#{name ? " #{name}" : ""}#{version ? " #{version}" : ""}>"; end

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
    # @overload initialize(&block)
    #   Using a block, the API is more terse and the tasks are automatically generated
    #   when the block is closed (Uses a {DSLWrapper}). This is the preferred syntax!
    #
    #   @example
    #       Relapse::Project.new do
    #         name "My Application"
    #         version "1.2.4"
    #         add_build :source do
    #           add_archive :tar_gz do
    #             extension ".tgz"
    #           end
    #         end
    #       end
    #
    #   @yield [] Block is evaluated in context of a {DSLWrapper} wrapping self.
    #
    # @overload initialize(&block)
    #   Using a block that takes a parameter, self is passed, and so the API is similar to a Gem::Specification.
    #   The tasks are automatically generated when the block is closed
    #
    #   @example
    #       Relapse::Project.new do |p|
    #         p.name = "My Application"
    #         p.version = "1.2.4"
    #         p.add_build :source do |b|
    #           b.add_archive :tar_gz do |a|
    #             a.extension = ".tgz"
    #           end
    #         end
    #       end
    #
    #   @yieldparam project [Project] new project
    #
    # @overload initialize
    #   Without using blocks, the {Project} can be accessed directly. It is recommended that a block is used.
    #
    #   @example
    #       project = Relapse::Project.new
    #       project.name = "My Application"
    #       project.version = "1.2.4"
    #       builder = project.add_build :source
    #       archiver = builder.add_archive :zip
    #       archiver.extension = ".tgz"
    #       project.generate_tasks # This has to be done manually.
    #
    def initialize(&block)
      super()

      @builders = []
      @links = {}
      @files = Rake::FileList.new
      @exposed_files = Rake::FileList.new
      @output_path = DEFAULT_PACKAGE_FOLDER
      @verbose = true
      @create_md5s = false
      @name = @underscored_name = @underscored_version = nil
      @version = @executable = nil

      setup

      if block_given?
        if block.arity == 0
          DSLWrapper.new(self, &block)
        else
          yield self
        end

        generate_tasks
      end
    end

    # Add a type of output to produce. Must define at least one of these.
    # @see #initialize
    # @param type [:osx_app, :source, :windows_folder, :windows_folder_from_ruby_dist, :windows_installer, :windows_standalone]
    # @return [Project] self
    def add_build(type, &block)
      raise ArgumentError, "Unsupported output type #{type}" unless Builders.has_type? type
      raise ConfigError, "Already have output #{type.inspect}" if @builders.any? {|b| b.type == type }

      builder = Builders[type].new(self)
      @builders << builder

      if block_given?
        if block.arity == 0
          DSLWrapper.new(builder, &block)
        else
          yield builder
        end
      end

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

    # Generates all tasks required by the user. Automatically called at the end of the block, if {#initialize} is given a block.
    # @return [Project] self
    def generate_tasks
      raise ConfigError, "Must specify at least one valid output for this OS with #add_build before tasks can be generated" if @builders.empty?

      # Even if there are builders specified, none may work on this platform.
      return if active_builders.empty?

      build_outputs = []
      build_groups = Hash.new {|h, k| h[k] = [] }

      active_builders.each do |builder|
        builder.send :generate_tasks
        task_name = "build:#{builder.type.to_s.tr("_", ":")}"

        if builder.type.to_s =~ /_/
          task_group = builder.send :task_group
          build_groups[task_group] << task_name
          build_outputs << "build:#{task_group}"
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
    def setup; end

    protected
    # @return [Array<Builder>]
    def active_builders
      @builders.find_all(&:valid_for_platform?)
    end

    protected
    # Generates the general tasks for compressing folders.
    def generate_archive_tasks
      return if active_builders.empty?

      windows_tasks = []
      osx_tasks = []
      top_level_tasks = []
      active_builders.each do |builder|
        output_task = builder.type.to_s.sub '_', ':'

        archivers = active_archivers(builder)
        archivers.each do |archiver|
          archiver.send :generate_tasks, output_task, builder.send(:folder)
        end

        desc "Package all #{builder.type}"
        task "package:#{output_task}" => archivers.map {|c| "package:#{output_task}:#{c.type}" }

        case output_task
          when /^windows:/
            windows_tasks << "package:#{output_task}"
            top_level_tasks << "package:windows" unless top_level_tasks.include? "package:windows"
          when /^osx:/
            osx_tasks << "package:#{output_task}"
            top_level_tasks << "package:osx" unless top_level_tasks.include? "package:osx"
          else
            top_level_tasks << "package:#{output_task}"
        end
      end

      unless windows_tasks.empty?
        desc "Package all Windows"
        task "package:windows" => windows_tasks
      end

      unless osx_tasks.empty?
        desc "Package all OS X"
        task "package:osx" => osx_tasks
      end

      desc "Package all"
      task "package" => top_level_tasks

      self
    end

    protected
    def active_archivers(builder)
      # Use archivers specifically set on the builder and those set globally that aren't on the builder.
      archivers = builder.send(:active_archivers)
      archiver_types = archivers.map(&:type)

      archivers + super().reject {|a| archiver_types.include? a.type }
    end
  end
end