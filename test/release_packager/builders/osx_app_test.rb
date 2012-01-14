require File.expand_path("../../teststrap", File.dirname(__FILE__))

context ReleasePackager::Builders::OsxApp do
  setup { ReleasePackager::Project.new }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path

    topic.name = "Test"
    topic.version = "0.1"
    topic.files = source_files
    topic.readme = "README.txt"
    topic.osx_app_url = "org.frog.fish"
    # Just use the dev gems, but some won't work, so ignore them.
    topic.osx_app_gems = Gem.loaded_specs.values.reject {|g| %w[rake ocra].include? g.name }

    topic.add_output :osx_app
    topic.add_archive_format :tar_gz
  end

  context "no wrapper" do
    asserts(:generate_tasks).raises RuntimeError
  end

  context "invalid wrapper" do
    hookup { topic.osx_app_wrapper= "no file" }

    asserts(:generate_tasks).raises RuntimeError
  end

  context "valid wrapper" do
    hookup do
      topic.osx_app_wrapper = "../../../osx_app/RubyGosu App.app"
      topic.generate_tasks
    end

    context "tasks" do
      tasks = [
          [ :Task, "package", %w[package:osx] ],
          [ :Task, "package:osx", %w[package:osx:app] ],
          [ :Task, "package:osx:app", %w[package:osx:app:tar_gz] ],
          [ :Task, "package:osx:app:tar_gz", %w[pkg/test_0_1_OSX.tar.gz] ],

          [ :Task, "build", %w[build:osx] ],
          [ :Task, "build:osx", %w[build:osx:app] ],
          [ :Task, "build:osx:app", %w[pkg/test_0_1_OSX] ],

          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_0_1_OSX", source_files + ["../../../osx_app/RubyGosu App.app"]],
          [ :FileTask, "pkg/test_0_1_OSX.tar.gz", %w[pkg/test_0_1_OSX] ],
      ]

      test_tasks tasks
    end

    context "generate folder + tar.gz" do
      hookup { Rake::Task["package:osx:app:tar_gz"].invoke }

      asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_OSX/Test.app/Contents/Resources/test/#{f}") == File.read(f) } }
      asserts("readme copied to folder") { File.read("pkg/test_0_1_OSX/README.txt") == File.read("README.txt") }

      asserts("app folder is an executable file") { File.executable?("pkg/test_0_1_OSX/Test.app") }
      asserts("archive created") { File.size("pkg/test_0_1_OSX.tar.gz") > 0 }

      asserts("Main.rb is correct") do
        File.read("pkg/test_0_1_OSX/Test.app/Contents/Resources/Main.rb") == <<END
OSX_EXECUTABLE_FOLDER = File.expand_path("../../..", __FILE__)

# Really hacky fudge-fix for something oddly missing in the .app.
class Encoding
  UTF_7 = UTF_16BE = UTF_16LE = UTF_32BE = UTF_32LE = Encoding.list.first
end

require 'test/bin/test'
END
      end

      asserts("Info.plist is correct") do
        File.read("pkg/test_0_1_OSX/Test.app/Contents/Info.plist") == <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>11C74</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>RubyGosu App</string>
	<key>CFBundleIconFile</key>
	<string>Gosu</string>
	<key>CFBundleIdentifier</key>
	<string>org.frog.fish</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1.0</string>
	<key>DTCompiler</key>
	<string>4.0</string>
	<key>DTPlatformBuild</key>
	<string>10M2518</string>
	<key>DTPlatformVersion</key>
	<string>PG</string>
	<key>DTSDKBuild</key>
	<string>8S2167</string>
	<key>DTSDKName</key>
	<string>macosx10.4</string>
	<key>DTXcode</key>
	<string>0400</string>
	<key>DTXcodeBuild</key>
	<string>10M2518</string>
	<key>LSMinimumSystemVersionByArchitecture</key>
	<dict>
		<key>i386</key>
		<string>10.4.0</string>
		<key>ppc</key>
		<string>10.4.0</string>
		<key>x86_64</key>
		<string>10.6.0</string>
	</dict>
	<key>NSMainNibFile</key>
	<string>MainMenu</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
END
      end

      # Bundler should also be asked for, but it shouldn't be copied in.
      %w[release_packager rr riot yard].each do |gem|
        asserts("#{gem} gem folder copied") { File.directory?("pkg/test_0_1_OSX/Test.app/Contents/Resources/lib/#{gem}") }
      end

      denies("bundler gem folder copied")  { File.directory?("pkg/test_0_1_OSX/Test.app/Contents/Resources/lib/bundler") }

      denies("Info.plist contains old url") { File.read("pkg/test_0_1_OSX/Test.app/Contents/Info.plist") =~ %r[<string>org\.libgosu\.UntitledGame</string>] }
      asserts("Info.plist contains correct url") { File.read("pkg/test_0_1_OSX/Test.app/Contents/Info.plist") =~ %r[<string>org\.frog\.fish</string>]  }

      denies("archive is empty") { `7z x -so -bd -tgzip pkg/test_0_1_OSX.tar.gz | 7z l -si -bd -ttar` =~ /0 files, 0 folders/m }
  end
end
end