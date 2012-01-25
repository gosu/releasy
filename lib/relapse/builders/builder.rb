require "relapse/mixins/has_archivers"
require "relapse/mixins/exec"

module Relapse
module Builders
  # Builds release folders.
  # @abstract
  class Builder
    include Rake::DSL
    include Mixins::HasArchivers
    include Mixins::Exec

    # @return [Project] that this Builder belongs to.
    attr_reader :project
    # @return [String] Suffix on the folder generated, after name and version.
    attr_accessor :folder_suffix

    # @return [Symbol] Type of builder.
    def type; self.class::TYPE; end

    # Is the builder valid for the current platform (OS)?
    def valid_for_platform?; true; end

    def initialize(project)
      super()
      @project = project
      @folder_suffix = self.class::DEFAULT_FOLDER_SUFFIX
      setup
    end

    protected
    # @return [String] Called from the project, but users don't need to know about it.
    def task_group; type.to_s.split(/_/).first; end
    # @return [String] Output folder.
    def folder; "#{project.folder_base}#{folder_suffix.empty? ? '' : '_'}#{folder_suffix}"; end

    protected
    # Called by {#initalize}
    def setup; end

    protected
    # Copy a number of files into a folder, maintaining relative paths.
    def copy_files_relative(files, folder)
      files.each do |file|
        destination = File.join(folder, File.dirname(file))
        mkdir_p destination unless File.exists? destination
        cp file, destination
      end
    end
  end
end
end