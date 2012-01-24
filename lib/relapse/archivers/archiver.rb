require "relapse/mixins/exec"

module Relapse
module Archivers
  # @abstract
  class Archiver
    include Rake::DSL
    include Mixins::Exec

    attr_reader :project
    attr_accessor :extension

    def type; self.class::TYPE; end
    def initialize(project)
      @project = project
      @extension = self.class::DEFAULT_EXTENSION
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
      %[7z a -mmt -bd -t#{type} -mx9 "#{package(folder)}" "#{folder}"]
    end
  end
end
end