module Relapse
  module Mixins
    # Adds an {#exec} method that prints out if the project is verbose.
    module Exec
      protected
      def exec(command)
        puts command if project.verbose?
        result = %x[#{command}]
        puts result if project.verbose?
        result
      end
    end
  end
end