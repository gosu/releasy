module Releasy
  module Mixins
    # Adds an {#execute_command} method that prints out if the project is verbose.
    # Requires {Log} to be included.
    module ExecuteCommand
      protected
      def execute_command(command)
        info command
        result = Kernel.` command # Use Kernel.` because it is easily mocked, unlike `command`
        info result
        result
      end
    end
  end
end