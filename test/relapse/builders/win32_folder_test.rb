require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context Relapse::Builders::Win32Folder do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 folder as zip" do
    hookup do
      topic.add_output :win32_folder
      topic.add_archive_format :zip
    end

    test_active_builders

    if RUBY_PLATFORM =~ /win32|mingw/
      context "on Windows" do
        hookup { topic.generate_tasks }

        tasks = [
            [ :Task, "package", %w[package:win32] ],
            [ :Task, "package:win32", %w[package:win32:folder] ],
            [ :Task, "package:win32:folder", %w[package:win32:folder:zip] ],
            [ :Task, "package:win32:folder:zip", %w[pkg/test_app_0_1_WIN32.zip] ],

            [ :Task, "build", %w[build:win32] ],
            [ :Task, "build:win32", %w[build:win32:folder] ],
            [ :Task, "build:win32:folder", %w[pkg/test_app_0_1_WIN32] ],

            [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
            [ :FileCreationTask, "pkg/test_app_0_1_WIN32", source_files ],
            [ :FileTask, "pkg/test_app_0_1_WIN32.zip", %w[pkg/test_app_0_1_WIN32] ],
        ]

        test_tasks tasks

        context "generate folder + zip" do
          hookup { begin; Rake::Task["package:win32:folder:zip"].invoke; rescue; end }

          asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_app_0_1_WIN32/#{f}") == File.read(f) } }
          asserts("folder includes links") { File.read("pkg/test_app_0_1_WIN32/Website.url") == link_file }
          asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_app_0_1_WIN32/test_app.exe") > 0 }
          asserts("archive created and of reasonable size") { File.size("pkg/test_app_0_1_WIN32.zip") > 2**20 }
          asserts("uninstaller files have been removed") { FileList["pkg/test_app_0_1_WIN32/unins000.*"].empty? }
        end

        context "the builder itself" do
          setup { Relapse::Builders::Win32Folder.new(topic) }

          asserts(:folder_suffix).equals "WIN32"
          asserts(:temp_installer_script).equals "pkg/win32_folder.iss"
          asserts(:installer_name).equals "pkg/test_app_0_1_setup_to_folder.exe"
          asserts(:executable_name).equals "test_app.exe"
          asserts(:folder).equals "pkg/test_app_0_1_WIN32"
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