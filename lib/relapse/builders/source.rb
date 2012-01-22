require "relapse/builders/builder"

module Relapse
  module Builders
    # Creates a folder containing the application source.
    class Source < Builder
      TYPE = :source
      Builders.register self

      DEFAULT_FOLDER_SUFFIX = "SOURCE"

      def generate_tasks
        desc "Build source folder"
        task "build:source" => folder

        directory folder

        file folder => project.files do
          Rake::FileUtilsExt.verbose project.verbose?

          copy_files_relative project.files, folder
        end
      end
    end
  end
end