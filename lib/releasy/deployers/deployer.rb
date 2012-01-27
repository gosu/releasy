require "releasy/mixins/log"

module Releasy
  module Deployers
    # @abstract
    class Deployer
      include Rake::DSL
      include Mixins::Log

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
          deploy(folder + extension)
        end
      end
    end
  end
end