require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = "pkg/test_app_0_1_WIN32_EXE"

context Relapse::Builders::Win32Standalone do
  setup { Relapse::Builders::Win32Standalone.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "valid" do
    if Gem.win_platform?
      context "on Windows" do
        hookup do
          topic.ocra_parameters = "--no-enc"
          topic.executable_type = :console
          topic.icon = "test_app.ico"
          topic.generate_tasks
        end

        asserts(:valid_for_platform?)
        asserts(:folder_suffix).equals "WIN32_EXE"
        asserts(:executable_name).equals "test_app.exe"
        asserts(:folder).equals folder
        asserts(:icon=, "test_app.icns").raises Relapse::ConfigError, /icon must be a .ico file/

        context "tasks" do
          tasks = [
              [ :Task, "build:win32:standalone", %w[pkg/test_app_0_1_WIN32_EXE] ],
              [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
              [ :FileCreationTask, folder, source_files ],
          ]

          test_tasks tasks
        end

        context "generate folder" do
          hookup { redirect_bundler_gemfile { Rake::Task["build:win32:standalone"].invoke } }

          asserts("readme copied to folder") { same_contents? "#{folder}/README.txt", "README.txt" }
          asserts("license copied to folder") {  same_contents? "#{folder}/LICENSE.txt", "LICENSE.txt" }
          asserts("folder includes link") { File.read("#{folder}/Relapse website.url") == link_file }
          asserts("executable created in folder and is of reasonable size") { File.size("#{folder}/test_app.exe") > 2**20 }
          asserts("program output") { redirect_bundler_gemfile { %x[#{folder}/test_app.exe] } }.equals "test run!\n"
        end
      end
    else
      context "NOT on Windows" do
        denies(:valid_for_platform?)
      end
    end
  end
end