require 'digest/md5'

require "relapse/mixins/exec"

module Relapse
module Archivers
  # @abstract
  class Archiver
    include Rake::DSL
    include Mixins::Exec

    MD5_READ_SIZE = 128 * 64 # MD5 likes 128 byte chunks.

    # @return [Project] Project this Archiver was created by.
    attr_reader :project
    # @return [String] Extension of archive to be created (such as ".zip").
    attr_accessor :extension

    def type; self.class::TYPE; end

    def initialize(project)
      @project = project
      @extension = self.class::DEFAULT_EXTENSION
    end

    protected
    # Generate tasks to create the archive of this file.
    def generate_tasks(output_task, folder)
      pkg = package folder

      desc "Create #{pkg}"
      task "package:#{output_task}:#{type}" => pkg

      file pkg => folder do
        archive folder
      end
    end

    protected
    def archive(folder)
      pkg = package folder
      Rake::FileUtilsExt.verbose project.verbose?

      puts "Creating #{pkg}" if project.verbose?
      rm pkg if File.exist? pkg
      cd project.output_path do
        exec command(File.basename folder)
      end

      File.open("#{pkg}.MD5", "w") {|f| f.puts checksum(pkg) } if project.send :create_md5s?
    end

    protected
    def package(folder); "#{folder}#{extension[0, 1] == '.' ? '' : '.'}#{extension}"; end

    protected
    def command(folder)
      %[7z a -mmt -bd -t#{type} -mx9 "#{package(folder)}" "#{folder}"]
    end

    protected
    def checksum(filename)
      digest = Digest::MD5.new
      File.open(filename, "rb") do |file|
        digest << file.read(MD5_READ_SIZE) until file.eof?
      end

      digest.hexdigest
    end
  end
end
end