require "releasy/mixins/has_packagers"
require "releasy/mixins/utilities"
require "releasy/mixins/log"

module Releasy
module Builders
  # Builds release folders.
  # @abstract
  #
  # @attr suffix [String] Suffix on the folder generated, after name and version.
  class Builder
    include Rake::DSL
    include Mixins::HasPackagers
    include Mixins::Utilities
    include Mixins::Log

    # @return [Project] that this Builder belongs to.
    attr_reader :project

    attr_reader :suffix
    def suffix=(suffix)
      raise TypeError, "suffix must be a String" unless suffix.is_a? String
      @suffix = suffix
    end
    alias_method :folder_suffix, :suffix
    alias_method :folder_suffix=, :suffix=

    # @return [Symbol] Type of builder.
    def type; self.class::TYPE; end

    # Is the builder valid for the current platform (OS)?
    def valid_for_platform?; true; end

    def initialize(project)
      super()
      @project = project
      @suffix = self.class::DEFAULT_FOLDER_SUFFIX
      setup
    end

    protected
    # @return [String] Called from the project, but users don't need to know about it.
    def task_group; type.to_s.split(/_/).first; end
    # @return [String] Output folder.
    def folder; "#{project.folder_base}#{suffix.empty? ? '' : '_'}#{suffix}"; end

    protected
    # Called by {#initalize}
    def setup; end

    protected
    # Copy a number of files into a folder, maintaining relative paths.
    def copy_files_relative(files, folder)
      files.each do |file|
        destination = File.join(folder, File.dirname(file))
        mkdir_p destination, fileutils_options unless File.exists? destination
        cp file, destination, fileutils_options
      end
    end
  end
end
end