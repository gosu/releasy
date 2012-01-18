require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

FOLDER = 'pkg/test_app_0_1_WIN32_FROM_WRAPPER'

context Relapse::Builders::Win32FolderFromWrapper do
  setup { Relapse::Builders::Win32FolderFromWrapper.new new_project }

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not set/
  if windows?
    denies(:valid_for_platform?)
  else
    asserts(:valid_for_platform?)
  end

  context "invalid wrapper" do
    hookup do
      topic.wrapper = "whatever"
    end

    asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not valid/
  end

  context "valid" do
    hookup do
      stub(topic).valid_for_platform?.returns(true) # Need to do this so we can test on all platforms.
      topic.wrapper = win32_folder_wrapper
      topic.icon = "test_app.ico"
      topic.gemspecs = Bundler.definition.specs_for([:development])
      topic.generate_tasks
    end

    asserts(:folder_suffix).equals "WIN32_FROM_WRAPPER"
    asserts(:wrapper).equals win32_folder_wrapper
    asserts("gemspecs names") { topic.gemspecs.map(&:name) }.same_elements Bundler.definition.specs_for([:development]).map(&:name)

    context "tasks" do
      tasks = [
          [ :Task, "build:win32:folder_from_wrapper", [FOLDER] ],
          [ :FileTask, "pkg", [] ], # byproduct of using #directory
          [ :FileTask, FOLDER, source_files + [win32_folder_wrapper]],
      ]

      test_tasks tasks
    end

    context "generate" do
      hookup { Rake::Task["build:win32:folder_from_wrapper"].invoke }

      asserts("files copied to folder") { source_files.all? {|f| File.read("#{FOLDER}/src/#{f}") == File.read(f) } }
      asserts("readme copied to folder") { File.read("#{FOLDER}/README.txt") == File.read("README.txt") }
      asserts("license copied to folder") { File.read("#{FOLDER}/LICENSE.txt") == File.read("LICENSE.txt") }

      asserts("test_app.exe has been created") { File.exists?("#{FOLDER}/test_app.exe") }
      asserts("test_app.exe is correct") { File.read("#{FOLDER}/test_app.exe") == File.read("#{win32_folder_wrapper}/console.exe") }
      denies("console.exe left in folder") { File.exists?("#{FOLDER}/console.exe") }
      denies("windows.exe left in folder") { File.exists?("#{FOLDER}/windows.exe") }

      asserts("ruby.exe left in bin") { File.exists?("#{FOLDER}/bin/ruby.exe") }
      denies("rubyw.exe left in folder") { File.exists?("#{FOLDER}/bin/rubyw.exe") }

      asserts("plenty of dlls copied") { Dir["#{FOLDER}/bin/*.dll"].size >= 6 }

      asserts("relapse_runner.rb is correct") { File.read("#{FOLDER}/relapse_runner.rb").strip == File.read(data_file("relapse_runner.rb")).strip }

      %w[bundler rr riot yard].each do |gem|
        asserts("#{gem} gem folder copied") { File.exists?("#{FOLDER}/vendor/gems/#{gem}") }
      end
    end
  end
end