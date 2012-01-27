require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = File.join(output_path, "test_app_0_1_OSX")
app_folder = File.join(folder, "Test App.app")

osx_app_wrapper = Dir.chdir(project_path) { Dir["../wrappers/gosu-mac-wrapper-*.tar.gz"].first }
if osx_app_wrapper
  context Releasy::Builders::OsxApp do
    setup { Releasy::Builders::OsxApp.new new_project }

    teardown do
      Dir.chdir $original_path
      Rake::Task.clear
    end

    hookup do
      Dir.chdir project_path
    end

    asserts(:folder_suffix).equals "OSX"
    asserts(:encoding_excluded?).equals false
    asserts(:icon=, "test_app.ico").raises Releasy::ConfigError, /icon must be a .icns file/
    denies(:gemspecs).empty

    context "no wrapper" do
      hookup do
        topic.url = "org.frog.fish"
      end
      asserts(:generate_tasks).raises Releasy::ConfigError, /wrapper not set/
    end

    context "invalid wrapper" do
      hookup do
        topic.url = "org.frog.fish"
        topic.wrapper = "whatever"
      end

      asserts(:generate_tasks).raises Releasy::ConfigError, /wrapper not valid/
    end

    context "no url" do
      hookup do
        topic.wrapper = osx_app_wrapper
      end
      asserts(:generate_tasks).raises Releasy::ConfigError, /url not set/
    end

    context "valid" do
      hookup do
        topic.url = "org.frog.fish"
        topic.wrapper = osx_app_wrapper
        topic.icon = "test_app.icns"
        topic.gemspecs = gemspecs_to_use
        topic.exclude_encoding
        topic.send :generate_tasks
      end

      asserts(:folder_suffix).equals "OSX"
      asserts(:app_name).equals "Test App.app"
      asserts(:url).equals "org.frog.fish"
      asserts(:wrapper).equals osx_app_wrapper
      asserts("gemspecs correct") { topic.gemspecs == gemspecs_to_use }

      context "tasks" do
        tasks = [
            [ :Task, "build:osx:app", [folder] ],
            [ :FileCreationTask, '..', [] ], # byproduct of using #directory
            [ :FileCreationTask, output_path, [] ], # byproduct of using #directory
            [ :FileCreationTask, folder, source_files + [osx_app_wrapper]],
        ]

        test_tasks tasks
      end

      context "generate" do
        hookup { Rake::Task["build:osx:app"].invoke }

        asserts("files copied inside app") { source_files.all? {|f| same_contents? "#{app_folder}/Contents/Resources/application/#{f}", f } }
        asserts("readme copied to folder") { same_contents? "#{folder}/README.txt", "README.txt" }
        asserts("license copied to folder") { same_contents? "#{folder}/LICENSE.txt", "LICENSE.txt" }

        asserts("executable renamed") { File.exists?("#{app_folder}/Contents/MacOS/Test App") }
        if Gem.win_platform?
          asserts("set_app_executable.sh created and with correct line endings") { File.read("#{folder}/set_app_executable.sh") == File.read(data_file("set_app_executable.sh")) }
        else
          asserts("app is an executable") { File.executable?("#{app_folder}/Contents/MacOS/Test App") }
          denies("set_app_executable.sh created") { File.exists? "#{folder}/set_app_executable.sh" }
        end

        asserts("Gosu icon deleted") { not File.exists? "#{app_folder}/Contents/Resources/Gosu.icns" }
        asserts("icon is copied to correct location") { File.exists? "#{app_folder}/Contents/Resources/test_app.icns" }
        asserts("Main.rb is correct") { same_contents? "#{app_folder}/Contents/Resources/Main.rb", data_file("Main.rb") }
        asserts("Info.plist is correct") { same_contents? "#{app_folder}/Contents/Info.plist", data_file("Info.plist") }

        gemspecs_to_use.each do |gemspec|
          name = "#{gemspec.name}-#{gemspec.version}"
          asserts("#{name} gem folder copied") { File.directory? "#{app_folder}/Contents/Resources/vendor/gems/#{name}" }
          asserts("#{name} spec copied") { File.exists? "#{app_folder}/Contents/Resources/vendor/specifications/#{name}.gemspec" }
        end

        denies("default chingu gem left in app")  { File.exists?("#{app_folder}/Contents/Resources/lib/chingu") }

        helper(:enc_folder) { "#{app_folder}/Contents/Resources/lib/enc" }
        asserts("remaining encoding files") { Dir["#{enc_folder}/**/*.bundle"].map {|f| f[(enc_folder.size + 1)..-1] } }.same_elements %w[encdb.bundle iso_8859_1.bundle utf_16le.bundle trans/single_byte.bundle trans/transdb.bundle trans/utf_16_32.bundle]

        if RUBY_PLATFORM =~ /darwin/
          asserts("program output") { clear_all_env { %x["./#{app_folder}/Contents/MacOS/Test App"] } }.equals "test run!\n"
        end
      end
    end
  end
end