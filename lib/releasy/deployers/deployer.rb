require "releasy/mixins/log"


module Releasy
  module Deployers
    # @abstract
    class Deployer
      include Rake::DSL
      include Mixins::Log

      # Printed out while file is being transferred.
      WORKING_CHARACTER = "."

      attr_reader :project

      def type; self.class::TYPE; end

      def initialize(project)
        @project = project
        setup
      end

      protected
      def generate_tasks(archive_task, folder, extension)
        desc "#{type} <= #{archive_task.split(":")[0..-2].join(" ")} #{extension}"
        task "deploy:#{archive_task}:#{type}" => "package:#{archive_task}" do
          do_deploy(folder + extension)
        end
      end

      protected
      def do_deploy(file)
        heading "Deploying #{file} (#{(File.size(file).fdiv 1024).ceil}k) to #{self.class.name[/[^:]+$/]}"

        t = Time.now

        deploy file

        minutes, seconds = (Time.now - t).ceil.divmod 60
        hours, minutes = minutes.divmod 60
        duration = "%d:%02d:%02d" % [hours, minutes, seconds]

        heading "Successfully deployed file in #{duration}"

        nil
      end
    end
  end
end