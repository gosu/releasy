require "relapse/builder"

module Relapse
  module Builders
    class OsxApp < Builder
      def self.folder_suffix; "OSX"; end

      EXTRA_FOLDERS_OSX = {
          'nokogiri' => %w[ext],
          'fidgit' => %w[config media],
          'r18n-core' => %w[base locales],
          'clipboard' => %w[VERSION],
      }

      protected
      def create_tasks
        original_app = project.osx_app_wrapper
        raise "Project#osx_app_url not set" unless project.osx_app_url
        raise "Project#osx_app_wrapper not set" unless original_app
        raise "Project#osx_app_wrapper not valid .app folder" unless File.extname(original_app) == ".app" and File.directory? original_app

        folder = "#{project.folder_base}_#{folder_suffix}"
        new_app = "#{folder}/#{app_name}"

        directory folder

        desc "Build OS X app"
        task "build:osx:app" => folder

        file folder => project.files + [original_app] do
          # Copy the app files.
          cp_r original_app, new_app

          ## Copy my source files.
          copy_files_relative project.files, "#{new_app}/Contents/Resources/#{project.underscored_name}"

          # Copy accompanying files.
          cp project.readme, folder if project.readme
          cp project.license, folder if project.license

          copy_gems new_app
          create_main new_app
          edit_init new_app

          chmod 0755, "#{new_app}/Contents/MacOS/RubyGosu App"
        end
      end

      protected
      def app_name; "#{project.name}.app"; end

      protected
      def copy_gems(app)
        gem_dir = "#{app}/Contents/Resources/lib"

        # Don't include binary gems already in the .app or bundler, since it will get confused.
        gem_names = (project.osx_app_gems.map(&:name) - %w[bundler gosu texplay chipmunk]).sort

        # Copy my gems.
        puts "Copying gems to #{gem_dir}" if project.verbose?
        gem_names.each do |gem|
          gem_path = project.osx_app_gems.find {|g| g.name == gem }.full_gem_path
          puts "Copying gem: #{File.basename gem_path}" if project.verbose?
          cp_r File.join(gem_path, 'lib'), File.dirname(gem_dir)

          # Some gems use files outside of /lib, which is not supported by the .app!
          # NOTE: This will fail if multiple gems require the same extra files/folders to included!
          # TODO: The way the app is originally built needs to change to remove this workaround.
          Array(EXTRA_FOLDERS_OSX[gem]).each do |extra|
            puts "  - copying extra #{File.directory?(extra) ? "folder" : "file"}: #{extra}"
            cp_r File.expand_path(extra, gem_path), File.dirname(gem_dir)
          end
        end
      end

      protected
      def create_main(app)
        # Something for the .app to run -> just a little redirection file.
        puts "--- Creating Main.rb"
        File.open("#{app}/Contents/Resources/Main.rb", "w") do |file|
          file.puts <<END_TEXT
OSX_EXECUTABLE_FOLDER = File.expand_path("../../..", __FILE__)

# Really hacky fudge-fix for something oddly missing in the .app.
class Encoding
  UTF_7 = UTF_16BE = UTF_16LE = UTF_32BE = UTF_32LE = Encoding.list.first
end

load '#{project.underscored_name}/#{project.executable}'
END_TEXT
        end
      end

      protected
      def edit_init(app)
        file = "#{app}/Contents/Info.plist"
        # Edit the info file to be specific for my game.
        puts "--- Editing init"
        info = File.read(file)
        info.sub!('<string>org.libgosu.UntitledGame</string>', "<string>#{project.osx_app_url}</string>")
        File.open(file, "w") {|f| f.puts info }
      end
    end
  end
end