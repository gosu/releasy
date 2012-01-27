module Releasy
  module Mixins
    # Adds an {#exec} method that prints out if the project is verbose.
    module Exec
      protected
      def exec(command)
        info command
        result = %x[#{command}]
        info result
        result
      end
    end
  end
end