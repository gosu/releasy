require "releasy/builders/builder"
require "releasy/mixins/has_gemspecs"
require "releasy/mixins/can_exclude_encoding"

module Releasy
  module Builders
    # Builds an OS X application bundle.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :osx_app do
    #       wrapper "gosu-mac-wrapper-0.7.41.tar.gz" # Required, see {#wrapper=}.
    #       url "com.cheese.myapp"                   # Required
    #       icon "media/icon.icns"                   # Optional
    #       exclude_encoding                         # Optional
    #       add_package :dmg                         # Optional
    #     end
    #   end
    #
    # @attr icon [String] Optional filename of icon to show on executable/installer (.icns).
    class OsxApp < Builder
      include Mixins::HasGemspecs
      include Mixins::CanExcludeEncoding

      TYPE = :osx_app

      DEFAULT_FOLDER_SUFFIX = "OSX"

      # Binary gems included in app.
      BINARY_GEMS = %w[gosu texplay chipmunk]
      # Icon type used in the app.
      ICON_EXTENSION = ".icns"
      # Source gems included in app that we should remove.
      SOURCE_GEMS_TO_REMOVE = %w[chingu]

      # Encoding files that are required, even if we don't need most of them if we select to {#exclude_encoding}.
      REQUIRED_ENCODING_FILES = %w[encdb.bundle iso_8859_1.bundle utf_16le.bundle trans/single_byte.bundle trans/transdb.bundle trans/utf_16_32.bundle]

      VALID_GOSU_WRAPPER = /gosu-mac-wrapper-\d\.\d\.\d+.tar.gz/

      Builders.register self

      # @return [String] Name of .app directory used as the framework for osx app release.
      attr_accessor :wrapper
      # @return [String] Inverse url of application (e.g. 'org.supergames.blasterbotsfrommars')
      attr_accessor :url

      # @return [String] Optional filename of icon to show on app (.icns).
      attr_reader :icon

      def icon=(icon)
        raise ArgumentError, "icon must be a #{ICON_EXTENSION} file" unless File.extname(icon) == ICON_EXTENSION
        @icon = icon
      end

      protected
      def generate_tasks
        raise ConfigError, "#url not set" unless url
        raise ConfigError, "#url not valid: #{url}" unless url =~ /\w+(\.\w+)*/i
        raise ConfigError, "#wrapper not set" unless wrapper
        raise ConfigError, "#wrapper not valid wrapper: #{wrapper}" unless File.basename(wrapper) =~ VALID_GOSU_WRAPPER

        desc "Build OS X app"
        task "build:osx:app" => folder

        file folder => project.files + [wrapper] do
          mkdir_p folder, fileutils_options
          build
        end
      end

      protected
      def build
        raise ConfigError, "#wrapper file does not exist: #{wrapper}" unless File.exists? wrapper

        new_app = File.join folder, app_name

        # Copy the app files.
        execute_command %[7z x -so -bd "#{wrapper}" 2>#{null_file} | 7z x -si -mmt -bd -ttar -o"#{folder}"]
        mv File.join(folder, "RubyGosu App.app"), new_app, fileutils_options

        ## Copy my source files.
        copy_files_relative project.files, File.join(new_app, 'Contents/Resources/application')

        remove_encoding if encoding_excluded?

        # Copy accompanying files.
        project.exposed_files.each {|file| cp file, folder, fileutils_options }

        copy_gems vendored_gem_names(BINARY_GEMS), File.join(new_app, 'Contents/Resources/vendor')
        create_main new_app
        edit_init new_app
        remove_gems new_app
        rename_executable new_app
        update_icon new_app
        create_executable_setter
      end

      protected
      def setup
        @icon = nil
        @url = nil
        @wrapper = nil
        super
      end

      protected
      def app_name; "#{project.name}.app"; end

      protected
      def create_executable_setter
        if Releasy.win_platform?
          # Ensure that we have a Unixy file by setting binary ("wb") mode on Windows.
          File.open(File.join(folder, "set_app_executable.sh"), "wb") do |file|
            file.puts <<END
#!/bin/sh
chmod a+x "./#{app_name}/Contents/MacOS/#{project.name}"
echo "Made #{app_name} executable"
END

          end
        end
      end

      protected
      def remove_encoding
        encoding_files = Dir[File.join folder, "#{app_name}/Contents/Resources/lib/enc/**/*.bundle"]
        required_encoding_files = REQUIRED_ENCODING_FILES.map {|f| File.join folder, "#{app_name}/Contents/Resources/lib/enc", f }
        rm_r encoding_files - required_encoding_files, fileutils_options
      end

      protected
      def rename_executable(app)
        new_executable = "#{app}/Contents/MacOS/#{project.name}"
        mv "#{app}/Contents/MacOS/RubyGosu App" , new_executable, fileutils_options
        chmod 0755, new_executable, fileutils_options
      end

      protected
      # Remove unnecessary gems from the distribution.
      def remove_gems(app)
        SOURCE_GEMS_TO_REMOVE.each do |gem|
          rm_r "#{app}/Contents/Resources/lib/#{gem}", fileutils_options
        end
      end

      protected
      def update_icon(app)
        if icon
          rm "#{app}/Contents/Resources/Gosu.icns", fileutils_options
          cp icon, "#{app}/Contents/Resources", fileutils_options
        end
      end

      protected
      def create_main(app)
        # Something for the .app to run -> just a little redirection file.
        info "Creating Main.rb"
        File.open("#{app}/Contents/Resources/Main.rb", "w") do |file|
          file.puts <<END_TEXT
Dir[File.expand_path("../vendor/gems/*/lib", __FILE__)].each do |lib|
  $LOAD_PATH.unshift lib
end

OSX_EXECUTABLE_FOLDER = File.expand_path("../../..", __FILE__)

# Really hacky fudge-fix for something oddly missing in the .app.
class Encoding
  UTF_7 = UTF_16BE = UTF_16LE = UTF_32BE = UTF_32LE = Encoding.list.first
end

load 'application/#{project.executable}'
END_TEXT
        end
      end

      protected
      def edit_init(app)
        file = "#{app}/Contents/Info.plist"
        # Edit the info file to be specific for my game.
        info "Editing init"
        info = File.read(file)
        info.sub!('<string>Gosu</string>', "<string>#{File.basename(icon).chomp(File.extname(icon))}</string>") if icon
        info.sub!('<string>RubyGosu App</string>', "<string>#{project.name}</string>")
        info.sub!('<string>org.libgosu.UntitledGame</string>', "<string>#{url}</string>")
        File.open(file, "w") {|f| f.puts info }
      end
    end
  end
end