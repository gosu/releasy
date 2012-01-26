module Releasy
  module Deployers
    # @abstract
    class Deployer
      include Rake::DSL

      attr_reader :project

      def type; self.class::TYPE; end

      def initialize(project)
        @project = project
        setup
      end

      protected
      def generate_tasks(archive_task, file)
        desc "#{type} <= #{archive_task.tr(":", " ")}"
        task "deploy:#{archive_task}:#{type}" => "package:#{archive_task}" do
          deploy file
        end
      end
    end
  end
end