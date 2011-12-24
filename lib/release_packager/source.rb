module ReleasePackager
  module Source
    SOURCE_SUFFIX = "SOURCE"

    protected
    def create_source_folder
      folder = "#{folder_base}_#{SOURCE_SUFFIX}"

      desc "Create source folder"
      task "release:source" => folder

      file folder => files do
        folder = "#{folder_base}_SOURCE"
        mkdir_p folder
        cp_r files, folder
      end
    end
  end
end