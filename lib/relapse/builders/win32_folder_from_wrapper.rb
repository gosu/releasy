require "relapse/builders/win32_builder"

module Relapse
  module Builders
    # Wraps up application in a pre-made wrapper. If building on Windows, use :win32_folder instead, since it will be much smaller.
    class Win32FolderFromWrapper < Win32Builder
      def self.folder_suffix; "WIN32"; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        directory folder

        file folder => project.files do
          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }

          copy_gems vendored_gem_names([]), folder
        end

        desc "Build source/exe folder #{project.version} [Innosetup]"
        task "build:win32:folder_non_native" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end