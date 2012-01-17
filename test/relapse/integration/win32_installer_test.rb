require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context "win32 installer as zip" do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
    topic.add_output :win32_installer do |o|
      o.start_menu_group = "Relapse Test Apps"
      o.ocra_parameters = "--no-enc"
      o.icon = "test_app.ico"
      o.license = "LICENSE.txt"
      o.readme = "README.txt"
      o.executable_type = :console
    end
    topic.add_archive_format :zip
  end

  active_builders_valid

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
        hookup do
          redirect_bundler_gemfile { Rake::Task["package:win32:installer:zip"].invoke }
        end

        asserts("readme copied to folder") { File.read("pkg/test_app_0_1_WIN32_INSTALLER/README.txt") == File.read("README.txt") }
        asserts("license copied to folder") { File.read("pkg/test_app_0_1_WIN32_INSTALLER/LICENSE.txt") == File.read("LICENSE.txt") }
        asserts("folder includes link") {  File.read("pkg/test_app_0_1_WIN32_INSTALLER/Relapse website.url") == link_file }
        asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_app_0_1_WIN32_INSTALLER/test_app_setup.exe") > 2**20 }
        asserts("archive created") { File.exists? "pkg/test_app_0_1_WIN32_INSTALLER.zip" }
        asserts("archive contains expected files") { `7z l pkg/test_app_0_1_WIN32_INSTALLER.zip` =~ /4 files, 1 folders/m }
      end
    end
  else
    context "NOT on Windows" do
      asserts(:active_builders).empty
    end
  end
end