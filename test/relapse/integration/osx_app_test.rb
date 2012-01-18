require File.expand_path("../../teststrap", File.dirname(__FILE__))

context "OS X app as tar.gz" do
  setup { Relapse::Project.new }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path

    topic.name = "Test App"
    topic.version = "0.1"
    topic.files = source_files
    topic.exposed_files = %w[README.txt LICENSE.txt]
    topic.add_archive_format :tar_gz
    topic.add_output :osx_app do |o|
      o.url = "org.frog.fish"
      # Just use the dev gems, but some won't work, so ignore them.
      o.gems = Bundler.definition.specs_for([:development])
      o.wrapper = app_wrapper
      o.icon = "test_app.icns"

    end
    topic.generate_tasks
  end

  helper(:data_file) do |file|
    File.expand_path("../data/#{file}", File.expand_path(__FILE__, $original_path))
  end

  active_builders_valid


  context "tasks" do
    tasks = [
        [ :Task, "package", %w[package:osx] ],
        [ :Task, "package:osx", %w[package:osx:app] ],
        [ :Task, "package:osx:app", %w[package:osx:app:tar_gz] ],
        [ :Task, "package:osx:app:tar_gz", %w[pkg/test_app_0_1_OSX.tar.gz] ],

        [ :Task, "build", %w[build:osx] ],
        [ :Task, "build:osx", %w[build:osx:app] ],
        [ :Task, "build:osx:app", %w[pkg/test_app_0_1_OSX] ],

        [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
        [ :FileCreationTask, "pkg/test_app_0_1_OSX", source_files + [app_wrapper]],
        [ :FileTask, "pkg/test_app_0_1_OSX.tar.gz", %w[pkg/test_app_0_1_OSX] ],
    ]

    test_tasks tasks
  end

  context "generate folder + tar.gz" do
    hookup { Rake::Task["build:osx:app"].invoke }

    asserts("files copied inside app") { source_files.all? {|f| File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/application/#{f}") == File.read(f) } }
    asserts("readme copied to folder") { File.read("pkg/test_app_0_1_OSX/README.txt") == File.read("README.txt") }
    asserts("license copied to folder") { File.read("pkg/test_app_0_1_OSX/LICENSE.txt") == File.read("LICENSE.txt") }

    asserts("executable renamed") { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/MacOS/Test App") }
    asserts("app is an executable (will fail in Windows)") { File.executable?("pkg/test_app_0_1_OSX/Test App.app/Contents/MacOS/Test App") }
    asserts("archive created") { File.size("pkg/test_app_0_1_OSX.tar.gz") > 0 }

    asserts("Gosu icon deleted") { not File.exists? "pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/Gosu.icns" }
    asserts("icon is copied to correct location") { File.exists? "pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/test_app.icns" }
    asserts("Main.rb is correct") { File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/Main.rb").strip == File.read(data_file("Main.rb")).strip }
    asserts("Info.plist is correct") { File.read("pkg/test_app_0_1_OSX/Test App.app/Contents/Info.plist").strip == File.read(data_file("Info.plist")).strip }

    # Bundler should also be asked for, but it shouldn't be copied in.
    %w[rr riot yard].each do |gem|
      asserts("#{gem} gem folder copied") { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/vendor/gems/#{gem}") }
    end

    denies("default chingu gem left in app")  { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/lib/chingu") }
    denies("bundler gem folder copied")  { File.exists?("pkg/test_app_0_1_OSX/Test App.app/Contents/Resources/vendor/gems/bundler") }
  end
end
