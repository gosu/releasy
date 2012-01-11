require 'bundler'

module ReleasePackager
  module Osx
    EXTRA_FOLDERS_OSX = {
        'nokogiri' => %w[ext],
        'fidgit' => %w[config media],
        'r18n-core' => %w[base locales],
        'clipboard' => %w[VERSION],
    }

    def build_osx_app
      file OSX_APP => "build:osx:app"

      desc "Generate #{OSX_APP} (OS X) v#{RELEASE_VERSION}"
      task "build:osx:app" => :readme do
        puts "--- Copying App #{TMP_OSX_PKG_DIR}"
        mkdir_p TMP_OSX_PKG_DIR

        raise "ERROR: Could not find #{BASE_OSX_APP}" unless File.exists? BASE_OSX_APP

        cp_r BASE_OSX_APP, TMP_OSX_APP

        # Copy my source files.
        puts "--- Copying source"
        mkdir_p TMP_OSX_SOURCE_DIR
        copy_files_relative files, TMP_OSX_SOURCE_DIR
        cp readme, TMP_OSX_PKG_DIR if readme
        #cp CHANGELOG_FILE, TMP_OSX_PKG_DIR

        copy_gems
        create_app_main
        edit_init
        set_app_executable
      end
    end

    protected
    def osx_app_folder; "#{underscored_name}_#{version}_OSX_APP"; end
    def osx_app; "#{name}.app"; end

    protected
    def copy_gems
      gems = Bundler.setup.gems
      # Don't include binary gems already in the .app or bundler, since it will get confused.
      gem_names = (gems.map(&:name) - %w[bundler gosu texplay chipmunk]).sort

      # Copy my gems.
      puts "--- Copying gems @ #{TMP_OSX_GEM_DIR}"
      gem_names.each do |gem|
        gem_path = gems.find {|g| g.name == gem }.full_gem_path
        puts "Copying gem: #{File.basename gem_path}"
        cp_r File.join(gem_path, 'lib'), File.dirname(TMP_OSX_GEM_DIR)

        # Some gems use files outside of /lib, which is not supported by the .app!
        # NOTE: This will fail if multiple gems require the same extra files/folders to included!
        # TODO: The way the app is originally built needs to change to remove this workaround.
        Array(EXTRA_FOLDERS_OSX[gem]).each do |extra|
          puts "  - copying extra #{File.directory?(extra) ? "folder" : "file"}: #{extra}"
          cp_r File.expand_path(extra, gem_path), File.dirname(TMP_OSX_GEM_DIR)
        end
      end
    end

    protected
    def create_app_main
      # Something for the .app to run -> just a little redirection file.
      puts "--- Creating Main.rb"
      mv RUN_FILE_OLD, RUN_FILE_NEW
      File.open(TMP_OSX_MAIN_FILE, "w") do |file|
        file.puts <<END_TEXT
OSX_EXECUTABLE_FOLDER = File.dirname(File.dirname(File.dirname(__FILE__)))

# Really hacky fudge-fix for something oddly missing in the .app.
class Encoding
  UTF_7 = UTF_16BE = UTF_16LE = UTF_32BE = UTF_32LE = Encoding.list.first
end

$LOAD_PATH.unshift File.join('#{APP}', 'bin')
require '#{File.basename(RUN_FILE_NEW)}'
END_TEXT
      end
    end

    protected
    def edit_init
      # Edit the info file to be specific for my game.
      puts "--- Editing init"
      info = File.read(TMP_OSX_INFO_FILE)
      info.sub!('org.libgosu.UntitledGame', GAME_URL)
      File.open(TMP_OSX_INFO_FILE, "w") {|f| f.puts info }
    end

    protected
    def set_app_executable
      # Ensure execute access to the startup file.
      puts "--- Setting execution privilege on App"
      chmod 0755, TMP_OSX_RUBY
    end
  end
end

=begin

GAME_URL = "com.github.spooner.games.#{underscore_name}"

RELEASE_FOLDER_OSX = "#{RELEASE_FOLDER_BASE}_OSX"

OSX_BUILD_DIR =  File.expand_path("~/gosu_wrappers")
BASE_OSX_APP = File.join(OSX_BUILD_DIR, "RubyGosu App.app")
TMP_OSX_PKG_DIR = File.join(OSX_BUILD_DIR, File.basename(RELEASE_FOLDER_OSX))
TMP_OSX_APP = File.join(TMP_OSX_PKG_DIR, OSX_APP)
TMP_OSX_SOURCE_DIR = File.join(TMP_OSX_APP, "Contents", "Resources", APP) # Where I copy my game source.
TMP_OSX_GEM_DIR = File.join(TMP_OSX_APP, "Contents", "Resources", 'lib') # Gem location.
TMP_OSX_INFO_FILE = File.join(TMP_OSX_APP, "Contents", "Info.plist")
TMP_OSX_MAIN_FILE = File.join(TMP_OSX_APP, "Contents", "Resources", "Main.rb")
TMP_OSX_RUBY = File.join(TMP_OSX_APP, "Contents", "MacOS", "RubyGosu App")

RUN_FILE_OLD = File.join(TMP_OSX_SOURCE_DIR, "bin/#{APP}.rbw")
RUN_FILE_NEW = RUN_FILE_OLD.sub('.rbw', '.rb')


=end
