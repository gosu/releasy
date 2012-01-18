require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::Win32Installer do
  setup { Relapse::Builders::Win32Installer.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  asserts(:folder_suffix).equals "WIN32_INSTALLER"
  asserts(:temp_installer_script).equals "pkg/win32_installer.iss"
  asserts(:folder).equals "pkg/test_app_0_1_WIN32_INSTALLER"
  asserts(:installer_name).equals "pkg/test_app_0_1_WIN32_INSTALLER/test_app_setup.exe"
  asserts(:icon=, "test_app.icns").raises Relapse::ConfigError, /icon must be a .ico file/

  context "valid" do
    if Gem.win_platform?
      context "on Windows" do
        hookup { topic.generate_tasks }

        asserts(:valid_for_platform?)

        context "tasks" do
          tasks = [
              [ :Task, "build:win32:installer", %w[pkg/test_app_0_1_WIN32_INSTALLER] ],
              [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
              [ :FileCreationTask, "pkg/test_app_0_1_WIN32_INSTALLER", source_files ],
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