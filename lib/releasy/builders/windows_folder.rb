require "releasy/builders/ocra_builder"
require 'releasy/windows_wrapper_maker'

module Releasy
  module Builders
    # Builds a folder containing Ruby + your source + a small Windows executable to run your executable script.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :windows_folder do
    #       icon "media/icon.ico"  # Optional
    #       exclude_encoding       # Optional
    #       add_package :zip       # Optional
    #     end
    #   end
    class WindowsFolder < OcraBuilder
      TYPE = :windows_folder
      DEFAULT_FOLDER_SUFFIX = "WIN32"

      Builders.register self

      protected
      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        file folder => project.files do
          mkdir_p project.output_path, **fileutils_options
          tmp_ocra_executable = "#{folder}.exe"

          execute_command %[#{ocra_command} --output "#{tmp_ocra_executable}" --debug-extract]

          # Extract the files from the executable.
          system tmp_ocra_executable
          rm tmp_ocra_executable, **fileutils_options

          extracted_folder_pattern = "#{File.dirname(folder)}/ocr*.tmp"
          extracted_folder = Dir[extracted_folder_pattern].first
          raise "Failed to find extracted folder matching: #{extracted_folder_pattern}" unless extracted_folder
          mv extracted_folder, folder, **fileutils_options

          maker = Releasy::WindowsWrapperMaker.new
          maker.build_executable("#{folder}/#{executable_name}", "src/#{project.executable}",
                                  :icon => icon, :windows => (effective_executable_type == :windows))

          create_link_files folder
          project.exposed_files.each {|file| cp file, folder, **fileutils_options }
        end

        desc "Build windows folder"
        task "build:windows:folder" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end