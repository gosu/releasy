module Relapse
  module Mixins
    module Exec
      def exec(command)
        puts command if project.verbose?
        result = %x[#{command}]
        puts result if project.verbose?
        result
      end
    end
  end
end