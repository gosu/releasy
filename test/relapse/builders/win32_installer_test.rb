require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = "pkg/test_app_0_1_WIN32_INSTALLER"

context Relapse::Builders::Win32Installer do
  setup { Relapse::Builders::Win32Installer.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "valid" do
    if Gem.win_platform?
      context "on Windows" do
        hookup do
          topic.start_menu_group = "Relapse Test Apps"
          topic.ocra_parameters = "--no-enc"
          topic.icon = "test_app.ico"
          topic.license = "LICENSE.txt"
          topic.readme = "README.txt"
          topic.executable_type = :console
          topic.generate_tasks
        end

        asserts(:valid_for_platform?)
        asserts(:start_menu_group).equals "Relapse Test Apps"
        asserts(:folder_suffix).equals "WIN32_INSTALLER"
        asserts(:temp_installer_script).equals "pkg/win32_installer.iss"
        asserts(:folder).equals folder
        asserts(:installer_name).equals "#{folder}/test_app_setup.exe"
        asserts(:icon=, "test_app.icns").raises Relapse::ConfigError, /icon must be a .ico file/

        context "tasks" do
          tasks = [
              [ :Task, "build:win32:installer", %w[pkg/test_app_0_1_WIN32_INSTALLER] ],
              [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
              [ :FileCreationTask, folder, source_files ],
          ]

          test_tasks tasks
        end

        context "generate folder" do
          hookup { redirect_bundler_gemfile { Rake::Task["build:win32:installer"].invoke } }

          asserts("readme copied to folder") { File.read("#{folder}/README.txt") == File.read("README.txt") }
          asserts("license copied to folder") { File.read("#{folder}/LICENSE.txt") == File.read("LICENSE.txt") }
          asserts("folder includes link") {  File.read("#{folder}/Relapse website.url") == link_file }
          asserts("executable created in folder and is of reasonable size") { File.size("#{folder}/test_app_setup.exe") > 2**20 }
        end
      end
    else
      context "NOT on Windows" do
        denies(:valid_for_platform?)
      end
    end
  end
end