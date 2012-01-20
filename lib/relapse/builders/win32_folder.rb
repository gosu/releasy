require "relapse/builders/win32_builder"
require 'relapse/exe_maker'

module Relapse
  module Builders
    # Builds a folder containing Ruby + your source + a small win32 executable to run your executable script.
    class Win32Folder < Win32Builder
      Builders.register self

      DEFAULT_FOLDER_SUFFIX = "WIN32"

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        directory project.output_path

        file folder => project.files do
          Rake::FileUtilsExt.verbose project.verbose?

          tmp_ocra_executable = "#{folder}.exe"

          exec %[#{ocra_command} --output "#{tmp_ocra_executable}" --debug-extract]

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