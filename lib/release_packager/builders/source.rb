require "release_packager/builder"

module ReleasePackager
  module Builders
    # Creates a folder containing the application source.
    class Source < Builder
      def self.folder_suffix; "SOURCE"; end

      protected
      def create_tasks
        folder = "#{project.folder_base}_#{folder_suffix}"

        desc "Build source folder"
        task "build:source" => folder

        directory folder

        file folder => project.files do
          copy_files_relative project.files, folder
        end
      end
    end
  end
end