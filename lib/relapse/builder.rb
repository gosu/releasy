module Relapse
  class Builder
    include Rake::DSL

    attr_reader :project

    def initialize(project)
      @project = project
      create_tasks
    end

    def self.valid_for_platform?; true; end

    def self.identifier
      id = name[/[a-z0-9]+$/i]
      id.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      id.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      id.downcase!
      id.to_sym
    end

    def self.group
      identifier.to_s.split(/_/).first
    end

    protected
    def folder_suffix; self.class.folder_suffix; end

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