require "releasy/builders/builder"

module Releasy
  module Builders
    # Creates a folder containing the application source.
    class Source < Builder
      TYPE = :source
      Builders.register self

      DEFAULT_FOLDER_SUFFIX = "SOURCE"

      protected
      def generate_tasks
        desc "Build source"
        task "build:source" => folder

        file folder => project.files do
          mkdir_p folder, fileutils_options
          copy_files_relative project.files, folder
        end
      end
    end
  end
end