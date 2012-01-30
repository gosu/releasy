require "releasy/builders/ocra_builder"

module Releasy
  module Builders
    # Creates a completely standalone Windows executable.
    #
    # @note Startup of the executable created by this build takes a couple of seconds longer than running from the other windows builds, as the files are extracted into a temporary directory each time it is run. It is recommended to build with _:windows_folder_ or _:windows_installer_ instead of this, unless you really need to distribute the application as a single file.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :windows_standalone do
    #       icon "media/icon.ico"  # Optional
    #       exclude_encoding       # Optional
    #       add_package :zip       # Optional
    #     end
    #   end
    class WindowsStandalone < OcraBuilder
      TYPE = :windows_standalone
      DEFAULT_FOLDER_SUFFIX = "WIN32_EXE"

      Builders.register self

      protected
      # Self-extracting standalone executable.
      def generate_tasks
        file folder => project.files do
          mkdir_p folder, fileutils_options

          project.exposed_files.each {|file| cp file, folder, fileutils_options }

          create_link_files folder

          execute_command %[#{ocra_command} --output "#{folder}/#{executable_name}"]
        end

        desc "Build standalone exe #{project.version} [Ocra]"
        task "build:windows:standalone" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end