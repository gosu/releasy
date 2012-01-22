require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = 'pkg/test_app_0_1_WIN32_FROM_WRAPPER'
wrapper = File.join('..', windows_folder_wrapper)

context Relapse::Builders::WindowsFolderFromWrapper do
  setup { Relapse::Builders::WindowsFolderFromWrapper.new new_project }

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:folder_suffix).equals "WIN32"
  asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not set/
  denies(:gemspecs).empty

  if Gem.win_platform?
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
      topic.wrapper = wrapper
      topic.folder_suffix = "WIN32_FROM_WRAPPER" # Do disambiguate from the windows version of this.
      topic.icon = "test_app.ico"
      topic.executable_type = :console
      topic.gemspecs = gemspecs_to_use
      topic.generate_tasks
    end

    asserts(:folder_suffix).equals "WIN32_FROM_WRAPPER"
    asserts(:wrapper).equals wrapper
    asserts("gemspecs correct") { topic.gemspecs == gemspecs_to_use }

    context "tasks" do
      tasks = [
          [ :Task, "build:windows:folder_from_wrapper", [folder] ],
          [ :FileTask, "pkg", [] ], # byproduct of using #directory
          [ :FileTask, folder, source_files + [wrapper]],
      ]

      test_tasks tasks
    end

    context "generate" do
      hookup { Rake::Task["build:windows:folder_from_wrapper"].invoke }

      asserts("files copied to folder") { source_files.all? {|f| same_contents? "#{folder}/src/#{f}", f } }
      asserts("readme copied to folder") { same_contents? "#{folder}/README.txt", "README.txt" }
      asserts("license copied to folder") {  same_contents? "#{folder}/LICENSE.txt", "LICENSE.txt" }

      asserts("test_app.exe has been created") { File.exists?("#{folder}/test_app.exe") }
      asserts("test_app.exe is correct") { File.read("#{folder}/test_app.exe") == File.read("#{wrapper}/console.exe") }
      denies("console.exe left in folder") { File.exists?("#{folder}/console.exe") }
      denies("windows.exe left in folder") { File.exists?("#{folder}/windows.exe") }

      asserts("ruby.exe left in bin/") { File.exists?("#{folder}/bin/ruby.exe") }
      denies("rubyw.exe left in bin/") { File.exists?("#{folder}/bin/rubyw.exe") }

      asserts("plenty of dlls copied") { Dir["#{folder}/bin/*.dll"].size >= 6 }

      asserts("relapse_runner.rb is correct") { File.read("#{folder}/relapse_runner.rb").strip == File.read(data_file("relapse_runner.rb")).strip }

      gemspecs_to_use.each do |gemspec|
        name = "#{gemspec.name}-#{gemspec.version}"
        asserts("#{name} gem specification copied") { File.exists? "#{folder}/gemhome/specifications/#{name}.gemspec" }
        asserts("#{name} gem folder copied") { File.directory? "#{folder}/gemhome/gems/#{name}" }
      end

      %w[ray].each do |gem|
        denies("#{gem} gem specification left (unused)") { not Dir["#{folder}/gemhome/specifications/#{gem}*.gemspec"].empty? }
        denies("#{gem} gem folder left (unused)") { not Dir["#{folder}/gemhome/gems/#{gem}*"].empty? }
      end

      if Gem.win_platform?
        asserts("program output") { redirect_bundler_gemfile { %x[#{folder}/test_app.exe] } }.equals "test run!\n"
      end
    end
  end
end