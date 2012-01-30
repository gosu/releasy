module Releasy
  module Mixins
    module Utilities
      protected
      # Executes command, and prints out command and result only if the project is verbose.
      # Requires {Log} to be included.
      def execute_command(command)
        info command
        result = Kernel.` command # Use Kernel.` because it is easily mocked, unlike `command`
        info result
        result
      end

      protected
      # Is a particular command available on this system?
      def command_available?(command)
        find = Releasy.win_platform? ? "where" : "which"
        !!Kernel.`("#{find} #{command}")
      end
    end
  end
end