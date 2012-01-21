require "relapse/mixins/exec"

module Relapse
module Archivers
  # @abstract
  class Archiver
    include Rake::DSL
    include Mixins::Exec

    attr_reader :project
    attr_accessor :extension

    def self.type
      id = name[/[a-z0-9]+$/i]
      id.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      id.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      id.downcase!
      id.to_sym
    end
    def type; self.class.type; end

    def initialize(project)
      @project = project
      @extension = ".#{type.to_s.tr("_", ".")}"
    end

    def generate_tasks(output_task, folder)
      pkg = package folder

      desc "Create #{pkg}"
      task "package:#{output_task}:#{type}" => pkg

      file pkg => folder do
        Rake::FileUtilsExt.verbose project.verbose?

        puts "Creating #{pkg}" if project.verbose?
        rm pkg if File.exist? pkg
        cd project.output_path do
          exec command(File.basename folder)
        end
      end
    end

    protected
    def package(folder); "#{folder}#{extension[0, 1] == '.' ? '' : '.'}#{extension}"; end

    protected
    def command(folder)
      %[7z a -mmt -bd -t#{type} "#{package(folder)}" "#{folder}"]
    end
  end
end
end