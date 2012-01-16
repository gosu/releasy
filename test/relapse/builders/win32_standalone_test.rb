require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::Win32Standalone do
  setup { Relapse::Builders::Win32Standalone.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  asserts(:folder_suffix).equals "WIN32_EXE"
  asserts(:executable_name).equals "test_app.exe"
  asserts(:folder).equals "pkg/test_app_0_1_WIN32_EXE"
  asserts(:icon=, "test_app.icns").raises Relapse::ConfigError, /icon must be a .ico file/

  context "valid" do
    if windows?
      context "on Windows" do
        hookup { topic.generate_tasks }

        asserts(:valid_for_platform?)

        context "tasks" do
          tasks = [
              [ :Task, "build:win32:standalone", %w[pkg/test_app_0_1_WIN32_EXE] ],
              [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
              [ :FileCreationTask, "pkg/test_app_0_1_WIN32_EXE", source_files ],
          ]

          test_tasks tasks
        end
      end
    else
      context "NOT on Windows" do
        denies(:valid_for_platform?)
      end
    end
  end
end