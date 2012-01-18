require "relapse/builders/win32_builder"
require "relapse/mixins/has_gemspecs"

module Relapse
  module Builders
    # Wraps up application in a pre-made wrapper. If building on Windows, use :win32_folder instead, since it will be much smaller.
    class Win32FolderFromWrapper < Win32Builder
      include HasGemspecs

      # @return [String] Name of win32 directory used as the framework for release.
      attr_accessor :wrapper

      def valid_for_platform?; not windows?; end

      def self.folder_suffix; "WIN32_FROM_WRAPPER"; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        raise ConfigError, "#wrapper not set" unless wrapper
        raise ConfigError, "#wrapper not valid" unless File.directory? wrapper

        file folder => project.files + [wrapper] do
          cp_r wrapper, folder

          copy_files_relative project.files, File.join(folder, 'src')

          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }

          update_executables

          create_runner

          copy_gems vendored_gem_names([]), File.join(folder, 'vendor/gems')
        end

        desc "Build source/exe folder #{project.version} from wrapper"
        task "build:win32:folder_from_wrapper" => folder
      end

      protected
      def setup
        @wrapper = nil
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end

      protected
      def update_executables
        if effective_executable_type == :windows
          rm File.join(folder, 'bin/ruby.exe')
          rm File.join(folder, 'console.exe')
          mv File.join(folder, 'windows.exe'), File.join(folder, executable_name)
        else
          rm File.join(folder, 'bin/rubyw.exe')
          rm File.join(folder, 'windows.exe')
          mv File.join(folder, 'console.exe'), File.join(folder, executable_name)
        end
      end
      protected
      def create_runner
        # Something for the .app to run -> just a little redirection file.
        puts "--- Creating relapse_runner.rb"
        File.open("#{folder}/relapse_runner.rb", "w") do |file|
          file.puts <<END_TEXT
#{vendored_gem_names([]).inspect}.each do |gem|
  $LOAD_PATH.unshift File.expand_path("../vendor/gems/\#{gem}/lib", __FILE__)
end

load '#{project.executable}'
END_TEXT
        end
      end
    end
  end
end