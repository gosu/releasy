require "relapse/builders/windows_builder"
require "relapse/mixins/has_gemspecs"

module Relapse
  module Builders
    # Wraps up an application for Windows when not on Windows, based on a RubyInstaller distribution and installing Windows binary gems.
    #
    # The resulting package will be much larger than a Windows package created on Windows, since it will include
    # the whole Ruby distribution, not just files that are needed.
    #
    # Limitations:
    #   * Does not DLLs loaded from the system, which will have to be included manually if any are required by the application and no universally available in Windows installations.
    #   * Unless a gem is in pure Ruby or available as a pre-compiled binary gem, it won't work!
    class WindowsFolderFromRubyDist < WindowsBuilder
      include Mixins::HasGemspecs

      TYPE = :windows_folder_from_ruby_dist
      DEFAULT_FOLDER_SUFFIX = "WIN32"

      Builders.register self

      # @return [String] Path to windows distribution archive that has been manually downloaded from http://rubyinstaller.org/downloads/ (e.g. "rubies/ruby-1.9.2-p290-i386-mingw32.7z").
      attr_accessor :ruby_dist

      def valid_for_platform?; not Relapse.win_platform?; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        raise ConfigError, "#ruby_dist not set" unless ruby_dist
        raise ConfigError, "#ruby_dist not valid: #{ruby_dist}" unless File.exist?(ruby_dist) and File.extname(ruby_dist) == ".7z"

        directory project.output_path

        file folder => project.files + [ruby_dist] do
          build
        end

        desc "Build source/exe folder #{project.version} from wrapper"
        task "build:windows:folder_from_ruby_dist" => folder
      end

      protected
      def build
        Rake::FileUtilsExt.verbose project.verbose?

        copy_ruby_distribution

        copy_files_relative project.files, File.join(folder, 'src')

        create_link_files folder
        project.exposed_files.each {|file| cp file, folder }

        create_executable

        # Copy gems.
        destination = File.join(folder, 'vendor')
        downloaded_binary_gems = install_binary_gems destination
        copy_gems vendored_gem_names(downloaded_binary_gems), destination
      end

      protected
      def setup
        @ruby_dist = nil
        super
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end

      protected
      def copy_ruby_distribution
        archive_name = File.basename(ruby_dist).chomp(File.extname(ruby_dist))
        exec %[7z x "#{ruby_dist}" -o"#{File.dirname folder}"]
        mv File.join(File.dirname(folder), archive_name), folder
        rm_r File.join(folder, "share")
        unused_exe = effective_executable_type == :windows ? "ruby.exe" : "rubyw.exe"
        rm File.join(folder, "bin", unused_exe)
      end

      protected
      def create_executable
        maker = Relapse::WindowsWrapperMaker.new
        maker.build_executable("#{folder}/#{executable_name}", "src/#{project.executable}",
                               :windows => (effective_executable_type == :windows))
      end

      protected
      def install_binary_gems(destination)
        puts "Checking gems to see if any are binary" if project.verbose?
        binary_gems = []
        gemspecs.reject {|s| false }.each do |spec|
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
    end
  end
end