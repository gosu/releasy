require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context Relapse::Builders::Win32Standalone do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 standalone as 7z" do
    hookup do
      topic.add_output :win32_standalone do |o|
        o.ocra_parameters = "--no-enc"
      end
      topic.add_archive_format :"7z"
    end

    test_active_builders

    if windows?
      context "on Windows" do
        hookup { topic.generate_tasks }

        tasks = [
            [ :Task, "package", %w[package:win32] ],
            [ :Task, "package:win32", %w[package:win32:standalone] ],
            [ :Task, "package:win32:standalone", %w[package:win32:standalone:7z] ],
            [ :Task, "package:win32:standalone:7z", %w[pkg/test_app_0_1_WIN32_EXE.7z] ],

            [ :Task, "build", %w[build:win32] ],
            [ :Task, "build:win32", %w[build:win32:standalone] ],
            [ :Task, "build:win32:standalone", %w[pkg/test_app_0_1_WIN32_EXE] ],

            [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
            [ :FileCreationTask, "pkg/test_app_0_1_WIN32_EXE", source_files ],
            [ :FileTask, "pkg/test_app_0_1_WIN32_EXE.7z", %w[pkg/test_app_0_1_WIN32_EXE] ],
        ]

        test_tasks tasks

        context "generate folder + 7z" do
          hookup { Rake::Task["package:win32:standalone:7z"].invoke }

          asserts("readme copied to folder") { File.read("pkg/test_app_0_1_WIN32_EXE/README.txt") == File.read("README.txt") }
          asserts("license copied to folder") { File.read("pkg/test_app_0_1_WIN32_EXE/LICENSE.txt") == File.read("LICENSE.txt") }
          asserts("folder includes links") { File.read("pkg/test_app_0_1_WIN32_EXE/Website.url") == link_file }
          asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_app_0_1_WIN32_EXE/test_app.exe") > 2**20 }
          asserts("archive created") { File.exists? "pkg/test_app_0_1_WIN32_EXE.7z" }
          asserts("archive contains expected files") { `7z l pkg/test_app_0_1_WIN32_EXE.7z` =~ /4 files, 1 folders/m }
        end

        context "the builder itself" do
          setup { Relapse::Builders::Win32Standalone.new(topic) }

          asserts(:folder_suffix).equals "WIN32_EXE"
          asserts(:executable_name).equals "test_app.exe"
          asserts(:folder).equals "pkg/test_app_0_1_WIN32_EXE"
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