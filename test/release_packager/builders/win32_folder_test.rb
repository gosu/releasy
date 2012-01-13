require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context ReleasePackager::Builders::Win32Folder do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 folder as zip" do
    hookup do
      topic.add_output :win32_folder
      topic.add_archive :zip
      topic.generate_tasks
    end

    context "tasks" do
      tasks = [
          [ :Task, "package", %w[package:win32] ],
          [ :Task, "package:win32", %w[package:win32:folder] ],
          [ :Task, "package:win32:folder", %w[package:win32:folder:zip] ],
          [ :Task, "package:win32:folder:zip", %w[pkg/test_0_1_WIN32.zip] ],

          [ :Task, "build", %w[build:win32] ],
          [ :Task, "build:win32", %w[build:win32:folder] ],
          [ :Task, "build:win32:folder", %w[pkg/test_0_1_WIN32] ],

          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_0_1_WIN32", source_files ],
          [ :FileTask, "pkg/test_0_1_WIN32.zip", %w[pkg/test_0_1_WIN32] ],
      ]

      tasks.each do |type, name, prerequisites|
        asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
        asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
      end

      asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
    end

    context "generate folder + zip" do
      hookup { begin; Rake::Task["package:win32:folder:zip"].invoke; rescue; end }

      asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_WIN32/#{f}") == File.read(f) } }
      asserts("folder includes links") { File.read("pkg/test_0_1_WIN32/Website.url") == link_file }
      asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32/test.exe") > 0 }
      asserts("archive created and of reasonable size") { File.size("pkg/test_0_1_WIN32.zip") > 2**20 }
      asserts("uninstaller files have been removed") { FileList["pkg/test_0_1_WIN32/unins000.*"].empty? }
    end
  end
end