module ReleasePackager
  SOURCE_SUFFIX = "SOURCE"

  module Source
    protected
    def build_source_folder
      folder = "#{folder_base}_#{SOURCE_SUFFIX}"

      desc "Build source folder"
      task "build:source" => folder

      directory folder

      file folder => files do
        copy_files_relative files, folder
      end
    end
  end
end