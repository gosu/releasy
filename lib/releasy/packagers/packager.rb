require 'digest/md5'

require "releasy/mixins/utilities"
require "releasy/mixins/log"

module Releasy
module Packagers
  # Archives a build folder.
  #
  # @abstract
  # @attr extension [String] Extension of archive to be created (such as ".zip").
  class Packager
    include Rake::DSL
    include Mixins::Utilities
    include Mixins::Log

    MD5_READ_SIZE = 128 * 64 # MD5 likes 128 byte chunks.

    # @return [Project] Project this Packager was created by.
    attr_reader :project

    attr_reader :extension
    def extension=(extension)
      raise TypeError, "extension must be a String" unless extension.is_a? String
      raise ArgumentError, "extension must be valid, such as '.zip'" unless extension =~ /^\.[a-z0-9\.]+$/
      @extension = extension
    end

    def type; self.class::TYPE; end

    def initialize(project)
      @project = project
      @extension = self.class::DEFAULT_EXTENSION
    end

    protected
    # Generate tasks to create the archive of this file.
    def generate_tasks(output_task, folder, deployers)
      pkg = package folder

      deployers.each {|d| d.send :generate_tasks, "#{output_task}:#{type}", folder, extension }

      desc "Package #{output_task.tr(":", " ")} #{extension}"
      task "package:#{output_task}:#{type}" => pkg

      file pkg => folder do
        archive folder
      end
    end

    protected
    def archive(folder)
      pkg = package folder

      heading "Creating #{pkg}"
      rm pkg, **fileutils_options if File.exist? pkg
      cd project.output_path, **fileutils_options do
        execute_command command(File.basename folder)
      end

      File.open("#{pkg}.MD5", "w") {|f| f.puts checksum(pkg) } if project.send :create_md5s?
    end

    protected
    def package(folder); "#{folder}#{extension}"; end

    protected
    def command(folder)
      %[#{seven_zip_command} a -mmt -bd -t#{type} -mx9 "#{package(folder)}" "#{folder}"]
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