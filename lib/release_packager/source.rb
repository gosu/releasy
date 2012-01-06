module ReleasePackager
  SOURCE_SUFFIX = "SOURCE"

  module Source
    protected
    def build_source_folder
      folder = "#{folder_base}_#{SOURCE_SUFFIX}"

      desc "Create source folder"
      task "release:source" => folder

      file folder => files do
       copy_files_relative files, folder
      end
    end

    # Copy a number of files into a folder, maintaining relative paths.
    protected
    def copy_files_relative(files, folder)
      files.each do |file|
        destination = File.join(folder, File.dirname(file))
        mkdir_p destination unless File.exists? destination
        cp file, destination
      end
    end
  end
end