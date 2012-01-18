require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::OsxApp do
  setup { Relapse::Builders::OsxApp.new new_project }

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:icon=, "test_app.ico").raises Relapse::ConfigError, /icon must be a .icns file/

  context "no wrapper" do
    hookup do
      topic.url = "org.frog.fish"
    end
    asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not set/
  end

  context "invalid wrapper" do
    hookup do
      topic.url = "org.frog.fish"
      topic.wrapper = "whatever"
    end

    asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not valid/
  end

  context "no url" do
    hookup do
      topic.wrapper = osx_app_wrapper
    end
    asserts(:generate_tasks).raises Relapse::ConfigError, /url not set/
  end

  context "valid" do
    hookup do
      topic.url = "org.frog.fish"
      topic.wrapper = osx_app_wrapper
      topic.icon = "test_app.icns"
      topic.gemspecs = Bundler.definition.specs_for([:development])
      topic.generate_tasks
    end

    asserts(:folder_suffix).equals "OSX"
    asserts(:app_name).equals "Test App.app"
    asserts(:url).equals "org.frog.fish"
    asserts(:wrapper).equals osx_app_wrapper

    context "tasks" do
      tasks = [
          [ :Task, "build:osx:app", %w[pkg/test_app_0_1_OSX] ],
          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_app_0_1_OSX", source_files + [osx_app_wrapper]],
      ]

      test_tasks tasks
    end

    context "generate" do
      hookup { Rake::Task["build:osx:app"].invoke }

      asserts("files copied inside app") { source_files.all? {|f| File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/application/#{f}") == File.read(f) } }
      asserts("readme copied to folder") { File.read("pkg/test_app_0_1_OSX/README.txt") == File.read("README.txt") }
      asserts("license copied to folder") { File.read("pkg/test_app_0_1_OSX/LICENSE.txt") == File.read("LICENSE.txt") }

      asserts("executable renamed") { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/MacOS/Test App") }
      asserts("app is an executable (will fail in Windows)") { File.executable?("pkg/test_app_0_1_OSX/Test App.app/Contents/MacOS/Test App") }

      asserts("Gosu icon deleted") { not File.exists? "pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/Gosu.icns" }
      asserts("icon is copied to correct location") { File.exists? "pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/test_app.icns" }
      asserts("Main.rb is correct") { File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/Main.rb").strip == File.read(data_file("Main.rb")).strip }
      asserts("Info.plist is correct") { File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Info.plist").strip == File.read(data_file("Info.plist")).strip }

      %w[bundler rr riot yard].each do |gem|
        asserts("#{gem} gem folder copied") { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/vendor/gems/#{gem}") }
      end

      denies("default chingu gem left in app")  { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/lib/chingu") }
    end
  end
end