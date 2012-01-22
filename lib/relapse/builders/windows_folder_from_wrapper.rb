require "relapse/builders/windows_builder"
require "relapse/mixins/has_gemspecs"

module Relapse
  module Builders
    # Wraps up application in a pre-made wrapper. If building on Windows, use :windows_folder instead, since it will be much smaller.
    class WindowsFolderFromWrapper < WindowsBuilder
      include Mixins::HasGemspecs

      TYPE = :windows_folder_from_wrapper
      DEFAULT_FOLDER_SUFFIX = "WIN32"
      INCLUDED_BINARY_GEMS = { 'ray' => '0.2.0' }

      Builders.register self

      # @return [String] Name of Windows wrapper directory used as the framework for release.
      attr_accessor :wrapper

      def valid_for_platform?; not Relapse.win_platform?; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        raise ConfigError, "#wrapper not set" unless wrapper
        raise ConfigError, "#wrapper not valid: #{wrapper}" unless File.directory? wrapper

        directory project.output_path

        file folder => project.files + [wrapper] do
          Rake::FileUtilsExt.verbose project.verbose?

          cp_r wrapper, folder

          copy_files_relative project.files, File.join(folder, 'src')

          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }

          update_executables

          create_runner

          # Copy gems.
          destination = File.join(folder, 'gemhome')
          downloaded_binary_gems = install_binary_gems destination
          copy_gems vendored_gem_names(INCLUDED_BINARY_GEMS.keys + downloaded_binary_gems), destination
          delete_unnecessary_gems destination
        end

        desc "Build source/exe folder #{project.version} from wrapper"
        task "build:windows:folder_from_wrapper" => folder
      end

      protected
      def setup
        @wrapper = nil
        super
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
      def install_binary_gems(destination)
        puts "Checking gems to see if any are binary" if project.verbose?
        binary_gems = []
        gemspecs.reject {|g| INCLUDED_BINARY_GEMS.include? g.name }.each do |spec|
          puts "Checking gem #{spec.name} #{spec.version} to see if there is a Windows binary version" if project.verbose?
          # Find out what versions are available and if the required version is available as a windows binary, download and install that.
          versions = %x[gem list "#{spec.name}" --remote --all --prerelease]
          if versions =~ /#{spec.name} \(([^\)]*)\)/m
            version_string = $1
            platforms = version_string.split(/,\s*/).find {|s| s =~ /^#{spec.version}/ }.split(/\s+/)
            windows_platform = platforms.find {|p| p =~ /mingw|mswin/ }
            raise "Gem #{spec.name} is binary, but #{spec.version} does not have a published binary" if version_string =~ /mingw|mswin/ and not windows_platform

            if windows_platform
              puts "Installing Windows version of binary gem #{spec.name} #{spec.version}"
              # If we have a bundle file specified, then gem will _only_ install the version specified by it and not the one we request.
              bundle_gemfile = ENV['BUNDLE_GEMFILE']
              ENV['BUNDLE_GEMFILE'] = ''
              exec %[gem install "#{spec.name}" --remote --no-rdoc --no-ri --force --ignore-dependencies --platform "#{windows_platform}" --version "#{spec.version}" --install-dir "#{destination}"]
              ENV['BUNDLE_GEMFILE'] = bundle_gemfile
              binary_gems << spec.name
            end
          end
        end

        binary_gems
      end

      protected
      def delete_unnecessary_gems(destination)
        (INCLUDED_BINARY_GEMS.keys - gemspecs.map(&:name)).each do |gem|
          full_gem_name = "#{gem}-#{INCLUDED_BINARY_GEMS[gem]}"
          puts "Deleting unused Windows binary gem from wrapper: #{full_gem_name}" if project.verbose?
          rm_r "#{destination}/gems/#{full_gem_name}"
          rm_r "#{destination}/specifications/#{full_gem_name}.gemspec"
        end
      end

      protected
      def create_runner
        # Something for the .app to run -> just a little redirection file.
        puts "--- Creating relapse_runner.rb" if project.verbose?
        File.open("#{folder}/relapse_runner.rb", "w") do |file|
          file.puts <<END_TEXT
load '#{project.executable}'
END_TEXT
        end
      end
    end
  end
end