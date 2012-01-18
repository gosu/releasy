require "relapse/mixins/has_archivers"

module Relapse
module Builders
  class Builder
    include Rake::DSL
    include Mixins::HasArchivers

    attr_reader :project

    def self.type
      id = name[/[a-z0-9]+$/i]
      id.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      id.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      id.downcase!
      id.to_sym
    end

    def type; self.class.type; end
    def folder; "#{project.folder_base}_#{folder_suffix}"; end
    def valid_for_platform?; true; end
    def task_group; type.to_s.split(/_/).first; end
    def folder_suffix; self.class.folder_suffix; end

    def initialize(project)
      super()
      @project = project
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