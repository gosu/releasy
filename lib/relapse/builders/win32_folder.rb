require "relapse/builders/win32_builder"
require 'relapse/exe_maker'

module Relapse
  module Builders
    # Builds a folder containing Ruby + your source + a small win32 executable to run your executable script.
    class Win32Folder < Win32Builder
      Builders.register self

      def self.folder_suffix; "WIN32"; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        file folder => project.files do
          tmp_ocra_executable = "#{folder}.exe"

          command = %[#{ocra_command} --output "#{tmp_ocra_executable}" --debug-extract]
          puts command
          system command

          # Extract the files from the executable.
          system tmp_ocra_executable
          rm tmp_ocra_executable

          mv Dir["#{File.dirname(folder)}/ocr*\.tmp"].first, folder

          Relapse::ExeMaker.create("#{folder}/#{executable_name}", "src/#{project.executable}",
                                   :icon => icon, :windows => (effective_executable_type == :windows))

          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }
        end

        desc "Build source/exe folder #{project.version}"
        task "build:win32:folder" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end