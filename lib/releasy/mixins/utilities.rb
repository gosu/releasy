module Releasy
  module Mixins
    module Utilities
      protected
      # Executes command, and prints out command and result only if the project is verbose.
      # Requires {Log} to be included.
      # Returns true if the command succeeded. False if it failed.
      def execute_command(command)
        info command

        begin
          IO.popen command do |output|
            info output.gets.strip until output.eof?
          end

          true
        rescue Errno::ENOENT
          false
        end
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