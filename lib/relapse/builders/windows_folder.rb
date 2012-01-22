require "relapse/builders/windows_builder"
require 'relapse/windows_wrapper_maker'

module Relapse
  module Builders
    # Builds a folder containing Ruby + your source + a small Windows executable to run your executable script.
    class WindowsFolder < WindowsBuilder
      TYPE = :windows_folder
      DEFAULT_FOLDER_SUFFIX = "WIN32"

      Builders.register self

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

          maker = Relapse::WindowsWrapperMaker.new
          maker.build_executable("#{folder}/#{executable_name}", "src/#{project.executable}",
                                  :icon => icon, :windows => (effective_executable_type == :windows))

          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }
        end

        desc "Build source/exe folder #{project.version}"
        task "build:windows:folder" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end