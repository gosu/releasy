module Releasy
  module Mixins
    module Utilities
      class << self
        attr_accessor :seven_zip_command
      end

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
      # Finds 7z, by hook or by crook.
      def seven_zip_command
        Utilities.seven_zip_command ||= begin
          if command_available? "7za"
            "7za" # Installed standalone command line version. Included with CLI and GUI releases.
          elsif command_available? "7z"
            "7z" # Installed CLI version only included with gui version.
          elsif Releasy.win_platform?
            %["#{File.expand_path("../../../../bin/7za.exe", __FILE__)}"]
          else
            raise CommandNotFoundError, "Failed to find 7-ZIP; see readme for details of how to install"
          end
        end
      end

      protected
      # Is a particular command available on this system?
      def command_available?(command)
        find = Releasy.win_platform? ? "where" : "which"
        Kernel.`("#{find} #{command}").length > 0
      end

      protected
      def null_file; Releasy.win_platform? ? "NUL" : "/dev/null"; end

    end
  end
end