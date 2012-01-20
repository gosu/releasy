require "relapse/builders/builder"
require "relapse/mixins/has_gemspecs"

module Relapse
  module Builders
    # @attr icon [String] Optional filename of icon to show on executable/installer (.icns).
    class OsxApp < Builder
      include Mixins::HasGemspecs

      Builders.register self

      DEFAULT_FOLDER_SUFFIX = "OSX"

      # Binary gems included in app.
      BINARY_GEMS = %w[gosu texplay chipmunk]
      # Icon type used in the app.
      ICON_EXTENSION = ".icns"
      # Source gems included in app that we should remove.
      SOURCE_GEMS_TO_REMOVE = %w[chingu]

      # @return [String] Name of .app directory used as the framework for osx app release.
      attr_accessor :wrapper
      # @return [String] Inverse url of application (e.g. 'org.supergames.blasterbotsfrommars')
      attr_accessor :url

      # @return [String] Optional filename of icon to show on app (.icns).
      attr_reader :icon

      def icon=(icon)
        raise ConfigError, "icon must be a #{ICON_EXTENSION} file" unless File.extname(icon) == ICON_EXTENSION
        @icon = icon
      end

      def generate_tasks
        raise ConfigError, "#url not set" unless url
        raise ConfigError, "#wrapper not set" unless wrapper
        raise ConfigError, "#wrapper not valid .app folder" unless File.extname(wrapper) == ".app" and File.directory? wrapper

        new_app = File.join folder, app_name

        directory folder

        desc "Build OS X app"
        task "build:osx:app" => folder

        file folder => project.files + [wrapper] do
          Rake::FileUtilsExt.verbose project.verbose?

          # Copy the app files.
          cp_r wrapper, new_app

          ## Copy my source files.
          copy_files_relative project.files, File.join(new_app, 'Contents/Resources/application')

          # Copy accompanying files.
          project.exposed_files.each {|file| cp file, folder }

          copy_gems vendored_gem_names(BINARY_GEMS), File.join(new_app, 'Contents/Resources/vendor/gems')
          create_main new_app
          edit_init new_app
          remove_gems new_app
          rename_executable new_app
          update_icon new_app
          create_executable_setter
        end
      end

      protected
      def setup
        @icon = nil
        @url = nil
        @wrapper = nil
      end

      protected
      def app_name; "#{project.name}.app"; end

      protected
      def create_executable_setter
        if Relapse.win_platform?
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
      def rename_executable(app)
        new_executable = "#{app}/Contents/MacOS/#{project.name}"
        mv "#{app}/Contents/MacOS/RubyGosu App" , new_executable
        chmod 0755, new_executable
      end

      protected
      # Remove unnecessary gems from the distribution.
      def remove_gems(app)
        SOURCE_GEMS_TO_REMOVE.each do |gem|
          rm_r "#{app}/Contents/Resources/lib/#{gem}"
        end
      end

      protected
      def update_icon(app)
        if icon
          rm "#{app}/Contents/Resources/Gosu.icns"
          cp icon, "#{app}/Contents/Resources"
        end
      end

      protected
      def create_main(app)
        # Something for the .app to run -> just a little redirection file.
        puts "--- Creating Main.rb" if project.verbose?
        File.open("#{app}/Contents/Resources/Main.rb", "w") do |file|
          file.puts <<END_TEXT
#{vendored_gem_names(BINARY_GEMS).inspect}.each do |gem|
  $LOAD_PATH.unshift File.expand_path("../vendor/gems/\#{gem}/lib", __FILE__)
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
        puts "--- Editing init" if project.verbose?
        info = File.read(file)
        info.sub!('<string>Gosu</string>', "<string>#{File.basename(icon).chomp(File.extname(icon))}</string>") if icon
        info.sub!('<string>RubyGosu App</string>', "<string>#{project.name}</string>")
        info.sub!('<string>org.libgosu.UntitledGame</string>', "<string>#{url}</string>")
        File.open(file, "w") {|f| f.puts info }
      end
    end
  end
end