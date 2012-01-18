require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::Win32Folder do
  setup { Relapse::Builders::Win32Folder.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  asserts(:folder_suffix).equals "WIN32"
  asserts(:temp_installer_script).equals "pkg/win32_folder.iss"
  asserts(:installer_name).equals "pkg/test_app_0_1_setup_to_folder.exe"
  asserts(:executable_name).equals "test_app.exe"
  asserts(:folder).equals "pkg/test_app_0_1_WIN32"
  asserts(:icon=, "test_app.icns").raises Relapse::ConfigError, /icon must be a .ico file/

  context "valid" do
    if Gem.win_platform?
      asserts(:valid_for_platform?)

      context "on Windows" do
        hookup { topic.generate_tasks }

        context "tasks" do
          tasks = [
              [ :Task, "build:win32:folder", %w[pkg/test_app_0_1_WIN32] ],
              [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
              [ :FileCreationTask, "pkg/test_app_0_1_WIN32", source_files ],
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