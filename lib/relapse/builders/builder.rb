require "relapse/mixins/has_archivers"
require "relapse/mixins/exec"

module Relapse
module Builders
  class Builder
    include Rake::DSL
    include Mixins::HasArchivers
    include Mixins::Exec

    # {Project} that this Builder belongs to.
    attr_reader :project
    # Suffix on the folder generated, after name and version.
    attr_accessor :folder_suffix

    def self.type
      id = name[/[a-z0-9]+$/i]
      id.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      id.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      id.downcase!
      id.to_sym
    end

    def type; self.class.type; end
    def folder; "#{project.folder_base}#{folder_suffix.empty? ? '' : '_'}#{folder_suffix}"; end
    def valid_for_platform?; true; end
    def task_group; type.to_s.split(/_/).first; end

    def initialize(project)
      super()
      @project = project
      @folder_suffix = self.class::DEFAULT_FOLDER_SUFFIX
      setup
    end

    protected
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