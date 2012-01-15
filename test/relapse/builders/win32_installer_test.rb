require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context Relapse::Builders::Win32Installer do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 installer as zip" do
    hookup do
      topic.add_output :win32_installer do |o|
        o.start_menu_group = "Test Apps"
        o.ocra_parameters = "--no-enc"
      end
      topic.add_archive_format :zip
    end

    test_active_builders

    if windows?
      context "on Windows" do
        hookup { topic.generate_tasks }

        tasks = [
            [ :Task, "package", %w[package:win32] ],
            [ :Task, "package:win32", %w[package:win32:installer] ],
            [ :Task, "package:win32:installer", %w[package:win32:installer:zip] ],
            [ :Task, "package:win32:installer:zip", %w[pkg/test_app_0_1_WIN32_INSTALLER.zip] ],

            [ :Task, "build", %w[build:win32] ],
            [ :Task, "build:win32", %w[build:win32:installer] ],
            [ :Task, "build:win32:installer", %w[pkg/test_app_0_1_WIN32_INSTALLER] ],

            [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
            [ :FileCreationTask, "pkg/test_app_0_1_WIN32_INSTALLER", source_files ],
            [ :FileTask, "pkg/test_app_0_1_WIN32_INSTALLER.zip", %w[pkg/test_app_0_1_WIN32_INSTALLER] ],
        ]

        test_tasks tasks

        context "generate folder + zip" do
          hookup { Rake::Task["package:win32:installer:zip"].invoke }

          asserts("readme copied to folder") { File.read("pkg/test_app_0_1_WIN32_INSTALLER/README.txt") == File.read("README.txt") }
          asserts("license copied to folder") { File.read("pkg/test_app_0_1_WIN32_INSTALLER/LICENSE.txt") == File.read("LICENSE.txt") }
          asserts("folder includes links") { File.read("pkg/test_app_0_1_WIN32_INSTALLER/Website.url") == link_file }
          asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_app_0_1_WIN32_INSTALLER/test_app_setup.exe") > 2**20 }
          asserts("archive created") { File.exists? "pkg/test_app_0_1_WIN32_INSTALLER.zip" }
          asserts("archive contains expected files") { `7z l pkg/test_app_0_1_WIN32_INSTALLER.zip` =~ /4 files, 1 folders/m }
        end

        context "the builder itself" do
          setup { topic.send(:active_builders).first }

          asserts(:folder_suffix).equals "WIN32_INSTALLER"
          asserts(:temp_installer_script).equals "pkg/win32_installer.iss"
          asserts(:folder).equals "pkg/test_app_0_1_WIN32_INSTALLER"
          asserts(:installer_name).equals "pkg/test_app_0_1_WIN32_INSTALLER/test_app_setup.exe"
        end
      end
    else
      context "NOT on Windows" do
        asserts(:active_builders).empty
        asserts(:generate_tasks).raises RuntimeError
      end
    end
  end
end