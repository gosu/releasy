require "relapse/builders/builder"

module Relapse
  module Builders
    # Creates a folder containing the application source.
    class Source < Builder
      Builders.register self

      def self.folder_suffix; "SOURCE"; end

      def generate_tasks
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