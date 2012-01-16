require "relapse/builder"

module Relapse
  module Builders
    class OsxApp < Builder
      def self.folder_suffix; "OSX"; end

      # Binary gems included in app.
      BINARY_GEMS = %w[gosu texplay chipmunk]

      # Source gems included in app that we should remove.
      SOURCE_GEMS_TO_REMOVE = %w[chingu]

      # @return [String] Name of .app directory used as the framework for osx app release.
      attr_accessor :wrapper
      # @return [String] Inverse url of application (e.g. 'org.supergames.blasterbotsfrommars')
      attr_accessor :url
      # @return [Array<Gem>] List of gems used by the application, which should usually be: Bundler.definition.gems_for([:default])
      attr_accessor :gems

      def generate_tasks
        raise "#url not set" unless url
        raise "#wrapper not set" unless wrapper
        raise "#wrapper not valid .app folder" unless File.extname(wrapper) == ".app" and File.directory? wrapper

        new_app = "#{folder}/#{app_name}"

        directory folder

        desc "Build OS X app"
        task "build:osx:app" => folder

        file folder => project.files + [wrapper] do
          # Copy the app files.
          cp_r wrapper, new_app

          ## Copy my source files.
          copy_files_relative project.files, "#{new_app}/Contents/Resources/application"

          # Copy accompanying files.
          cp project.readme, folder if project.readme
          cp project.license, folder if project.license

          copy_gems new_app
          create_main new_app
          edit_init new_app
          remove_gems new_app
          rename_executable new_app
        end
      end

      protected
      def setup
        @url = nil
        @wrapper = nil
        @gems = []
      end

      protected
      def app_name; "#{project.name}.app"; end

      protected
      # Don't include binary gems already in the .app or bundler, since it will get confused.
      def vendored_gem_names; (gems.map(&:name) - %w[bundler] - BINARY_GEMS).sort; end

      protected
      def rename_executable(app)
        new_executable = "#{app}/Contents/MacOS/#{project.name}"
        mv "#{app}/Contents/MacOS/RubyGosu App" , new_executable
        chmod 0755, new_executable
      end

      protected
      def copy_gems(app)

        puts "Copying gems into app" if project.verbose?
        mkdir_p "#{app}/Contents/Resources/vendor/gems"
        vendored_gem_names.each do |gem|
          gem_path = gems.find {|g| g.name == gem }.full_gem_path
          puts "Copying gem: #{File.basename gem_path}" if project.verbose?
          cp_r gem_path, "#{app}/Contents/Resources/vendor/gems/#{gem}"
        end
      end

      protected
      # Remove unnecessary gems from the distribution.
      def remove_gems(app)
        SOURCE_GEMS_TO_REMOVE.each do |gem|
          rm_r "#{app}/Contents/Resources/lib/#{gem}"
        end
      end

      protected
      def create_main(app)
        # Something for the .app to run -> just a little redirection file.
        puts "--- Creating Main.rb"
        File.open("#{app}/Contents/Resources/Main.rb", "w") do |file|
          file.puts <<END_TEXT
#{vendored_gem_names.inspect}.each do |gem|
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
        puts "--- Editing init"
        info = File.read(file)
        info.sub!('<string>RubyGosu App</string>', "<string>#{project.name}</string>")
        info.sub!('<string>org.libgosu.UntitledGame</string>', "<string>#{url}</string>")
        File.open(file, "w") {|f| f.puts info }
      end
    end
  end
end