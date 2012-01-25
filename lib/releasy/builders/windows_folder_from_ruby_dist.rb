require "releasy/builders/windows_builder"
require "releasy/mixins/has_gemspecs"

module Releasy
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

      # Files that are required for Tcl/Tk, but which are unlikely to be used in many applications.
      TCL_TK_FILES = %w[bin/tcl*-ri.dll bin/tk*-ri.dll
                         lib/tcltk
                         lib/ruby/tk*.rb
                         lib/ruby/1.*/tk* lib/ruby/1.*/tcl*
                         lib/ruby/1.*/i386-mingw32/tk* lib/ruby/1.*/i386-mingw32/tcl*
                       ]

      # Encoding files that are required, even if we don't need most of them if we select to {#exclude_encoding}.
      REQUIRED_ENCODING_FILES = %w[encdb.so iso_8859_1.so utf_16le.so trans/single_byte.so trans/transdb.so trans/utf_16_32.so]

      Builders.register self

      # @return [String] Path to windows distribution archive that has been manually downloaded from http://rubyinstaller.org/downloads/ (e.g. "rubies/ruby-1.9.2-p290-i386-mingw32.7z").
      attr_accessor :ruby_dist

      # Remove TCL/TK from package, which can save a significant amount of space if the application does not require them.
      # This is over 6MB uncompressed, which is a saving of 1.6MB when compressed with 7z format (LZMA).
      # @return [Project] self
      def exclude_tcl_tk; @exclude_tcl_tk = true; self; end

      def valid_for_platform?; not Releasy.win_platform?; end

      protected
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
        delete_excluded_files

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
      def delete_excluded_files
        # Remove TCL/TK dlls, lib folder and source.
        rm_r Dir[*(TCL_TK_FILES.map {|f| File.join(folder, f) })].uniq.sort if @exclude_tcl_tk

        # Remove Encoding files on Ruby 1.9
        if encoding_excluded? and ruby_dist =~ /1\.9\.\d/
          encoding_files = Dir[File.join folder, "lib/ruby/1.9.1/i386-mingw32/enc/**/*.so"]
          required_encoding_files = REQUIRED_ENCODING_FILES.map {|f| File.join folder, "lib/ruby/1.9.1/i386-mingw32/enc", f }
          rm_r encoding_files - required_encoding_files
        end
      end

      protected
      def setup
        @exclude_tcl_tk = false
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
        rm_r File.join(folder, "include") if File.exists? File.join(folder, "include")
        unused_exe = effective_executable_type == :windows ? "ruby.exe" : "rubyw.exe"
        rm File.join(folder, "bin", unused_exe)
      end

      protected
      def create_executable
        maker = Releasy::WindowsWrapperMaker.new
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