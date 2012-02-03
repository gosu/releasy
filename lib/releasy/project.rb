require 'set'

require 'releasy/dsl_wrapper'
require 'releasy/builders'
require 'releasy/packagers'
require 'releasy/deployers'
require "releasy/mixins/has_packagers"
require "releasy/mixins/can_exclude_encoding"
require "releasy/mixins/log"

module Releasy
  # A description of the Ruby application that is being build for release and what packages to make from it.
  #
  # @example
  #   Releasy::Project.new do
  #     name "My Application"
  #     version "1.2.4"
  #
  #     executable "bin/my_application.rbw"
  #     files "lib/**/*.rb", "config/**/*.yml", "media/**/*.*"
  #
  #     exposed_files "README.html", "LICENSE.txt"
  #     add_link "http://my_application.github.com", "My Application website"
  #     exclude_encoding
  #
  #     # Create a variety of releases, for all platforms.
  #     add_build :osx_app do
  #       url "com.github.my_application"
  #       wrapper "../osx_app/gosu-mac-wrapper-0.7.41.tar.gz"
  #       icon "media/icon.icns"
  #       add_package :tar_gz
  #     end
  #
  #     add_build :source do
  #       add_package :"7z"
  #     end
  #
  #     add_build :windows_folder do
  #       icon "media/icon.ico"
  #       add_package :exe
  #     end
  #
  #     add_build :windows_installer do
  #       icon "media/icon.ico"
  #       start_menu_group "Spooner Games"
  #       readme "README.html" # User asked if they want to view readme after install.
  #       license "LICENSE.txt" # User asked to read this and confirm before installing.
  #       add_package :zip
  #     end
  #
  #     add_deploy :github # Upload to a github project.
  #   end
  #
  # @attr underscored_name [String] Project name underscored (as used in file names), which will be derived from {#name}, but can be manually set.
  # @attr underscored_version [String] Version number, underscored so it can be used in file names, which will be derived from {#version}, but can be manually set.
  # @attr executable [String] Name of executable to run (defaults to 'bin/<underscored_name>')
  # @attr_reader folder_base [String] The path to the folders to create. All variations of output will be based on extending this path.
  # @attr files [Rake::FileList] List of files to include in package.
  # @attr exposed_files [Rake::FileList] Files which should always be copied into the archive folder root, so they are always visible to the user. e.g readme, change-log and/or license files.
  class Project
    include Rake::DSL
    include Mixins::HasPackagers
    include Mixins::CanExcludeEncoding
    include Mixins::Log

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
    def verbose; Mixins::Log.log_level = :verbose; end
    # Make the tasks give no output at all.
    # @return [nil]
    def silent; Mixins::Log.log_level = :silent; end

    # Create MD5 hashes for created archives.
    # @return [nil]
    def create_md5s; @create_md5s = true; nil; end
    def create_md5s?; @create_md5s; end
    protected :create_md5s?

    def exposed_files; @exposed_files; end
    def exposed_files=(*files); @exposed_files = Rake::FileList.new *files; end

    def files; @files; end
    def files=(*files); @files = Rake::FileList.new *files; end

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
    #       Releasy::Project.new do
    #         name "My Application"
    #         version "1.2.4"
    #         add_build :source do
    #           add_package :tar_gz do
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
    #       Releasy::Project.new do |p|
    #         p.name = "My Application"
    #         p.version = "1.2.4"
    #         p.add_build :source do |b|
    #           b.add_package :tar_gz do |a|
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
    #       project = Releasy::Project.new
    #       project.name = "My Application"
    #       project.version = "1.2.4"
    #       builder = project.add_build :source
    #       packager = builder.add_package :zip
    #       packager.extension = ".tgz"
    #       project.generate_tasks # This has to be done manually.
    #
    def initialize(&block)
      super()

      @builders = []
      @deployers = []
      @links = {}
      @files = Rake::FileList.new
      @exposed_files = Rake::FileList.new
      @output_path = DEFAULT_PACKAGE_FOLDER
      @create_md5s = false
      @name = @underscored_name = @underscored_version = nil
      @version = @executable = nil

      setup

      if block_given?
        if block.arity <= 0
          DSLWrapper.new(self, &block)
        else
          yield self
        end

        generate_tasks
      end
    end

    # Add a type of build to produce. Must define at least one of these.
    # @see #initialize
    # @param type [:osx_app, :source, :windows_folder, :windows_wrapped, :windows_installer, :windows_standalone]
    # @return [Project] self
    def add_build(type, &block)
      raise ArgumentError, "Unsupported output type #{type}" unless Builders.has_type? type
      raise ArgumentError, "Already have output #{type.inspect}" if @builders.any? {|b| b.type == type }

      builder = Builders[type].new(self)
      @builders << builder

      if block_given?
        if block.arity <= 0
          DSLWrapper.new(builder, &block)
        else
          yield builder
        end
      end

      builder
    end

    # Add a deployment method for archived packages.
    # @see #initialize
    # @param type [:github, :local, :rsync]
    # @return [Project] self
    def add_deploy(type, &block)
      raise ArgumentError, "Unsupported deploy type #{type}" unless Deployers.has_type? type
      raise ArgumentError, "Already have deploy #{type.inspect}" if @deployers.any? {|b| b.type == type }

      deployer = Deployers[type].new(self)
      @deployers << deployer

      if block_given?
        if block.arity <= 0
          DSLWrapper.new(deployer, &block)
        else
          yield deployer
        end
      end

      deployer
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
      raise ConfigError, "Must use #add_build at least once before tasks can be generated" if @builders.empty?

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
        desc "Build all #{group}"
        task "build:#{group}" => tasks
      end

      desc "Build #{description}"
      task "build" => build_outputs

      generate_archive_tasks

      self
    end

    # Full name of the project, including the version name E.g. "My Application" or "My Application 0.1"
    def description; name ? "#{name}#{version ? " #{version}" : ""}" : nil; end
    # Full underscored name of the project. E.g. "my_application" or "my_application_0_1"
    def underscored_description; underscored_name ? "#{underscored_name}#{version ? "_#{underscored_version}" : ""}" : nil; end
    # Base name of folders that will be created, such as "pkg/my_application" or "pkg/my_application_0_1"
    def folder_base; File.join(output_path, underscored_description.to_s); end

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

      windows_tasks = Set.new
      osx_tasks = Set.new
      top_level_tasks = Set.new

      active_builders.each do |builder|
        output_task = builder.type.to_s.sub '_', ':'

        packagers = active_packagers(builder)
        packagers.each do |packager|
          packager.send :generate_tasks, output_task, builder.send(:folder), @deployers

          unless @deployers.empty?
            task "deploy:#{output_task}:#{packager.type}" => @deployers.map {|d| "deploy:#{output_task}:#{packager.type}:#{d.type}" }
          end
        end

        @deployers.each do |deployer|
          task "deploy:#{output_task}:#{deployer.type}" => packagers.map {|a| "deploy:#{output_task}:#{a.type}:#{deployer.type}" }
        end

        task "package:#{output_task}" => packagers.map {|a| "package:#{output_task}:#{a.type}" }

        case output_task
          when /^windows:/
            windows_tasks << output_task
            top_level_tasks << 'windows'
          when /^osx:/
            osx_tasks << output_task
            top_level_tasks << 'osx'
          else
            top_level_tasks << output_task
        end
      end

      # Windows tasks.
      unless windows_tasks.empty?
        task "package:windows" => windows_tasks.map {|t| "package:#{t}" }

        generate_deploy_tasks windows_tasks
      end

      # OS X tasks.
      unless osx_tasks.empty?
        task "package:osx" => osx_tasks.map {|t| "package:#{t}" }

        generate_deploy_tasks osx_tasks
      end

      # Top level tasks.
      desc "Package #{description}"
      task "package" => top_level_tasks.map {|t| "package:#{t}" }

      generate_deploy_tasks top_level_tasks

      self
    end

    protected
    def generate_deploy_tasks(tasks)
      return if @deployers.empty?

      # Work out the namespace first. If there isn't one, then make a described (root) deploy task.
      tasks.first =~ /(.*):.*/
      namespace = $1
      deploy_task = namespace ? "deploy:#{namespace}" : 'deploy'

      unless namespace
        desc "Deploy #{description}"
        task 'deploy' => tasks.map {|t| "deploy:#{t}" }
      end

      @deployers.each do |d|
        task "#{deploy_task}:#{d.type}" => tasks.map {|t| "deploy:#{t}:#{d.type}" }
      end

      tasks.each do |t|
        task "deploy:#{t}" => @deployers.map {|d| "deploy:#{t}:#{d.type}" }
      end
    end

    protected
    def active_packagers(builder)
      # Use packagers specifically set on the builder and those set globally that aren't on the builder.
      packagers = builder.send(:active_packagers)
      packager_types = packagers.map(&:type)

      packagers + super().reject {|a| packager_types.include? a.type }
    end
  end
end