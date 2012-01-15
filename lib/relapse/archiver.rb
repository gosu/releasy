module Relapse
  # @abstract
  class Archiver
    include Rake::DSL

    attr_reader :project

    def self.identifier
      id = name[/[a-z0-9]+$/i]
      id.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
      id.gsub! /([a-z\d])([A-Z])/, '\1_\2'
      id.downcase!
      id.to_sym
    end
    def identifier; self.class.identifier; end

    def initialize(project)
      @project = project
    end

    def create_tasks(output_task, folder)
      pkg = package folder

      desc "Create #{pkg}"
      task "package:#{output_task}:#{identifier}" => pkg

      file pkg => folder do
        puts "Creating #{pkg}" if project.verbose?
        rm pkg if File.exist? pkg
        cd project.output_path do
          command = command(File.basename folder)
          puts command if project.verbose?
          output = %x[#{command}]
          puts output if project.verbose?
        end
      end
    end

    protected
    def extension; identifier.to_s.tr("_", "."); end
    def package(folder); "#{folder}.#{extension}"; end

    protected
    def command(folder)
      %[7z a -mmt -bd -t#{identifier} "#{package(folder)}" "#{folder}"]
    end
  end
end