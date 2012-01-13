require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context ReleasePackager::Builders::Win32Standalone do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 standalone as 7z" do
    hookup do
      topic.add_output :win32_standalone
      topic.add_archive :"7z"
      topic.generate_tasks
    end

    context "tasks" do
      tasks = [
          [ :Task, "package", %w[package:win32] ],
          [ :Task, "package:win32", %w[package:win32:standalone] ],
          [ :Task, "package:win32:standalone", %w[package:win32:standalone:7z] ],
          [ :Task, "package:win32:standalone:7z", %w[pkg/test_0_1_WIN32_EXE.7z] ],

          [ :Task, "build", %w[build:win32] ],
          [ :Task, "build:win32", %w[build:win32:standalone] ],
          [ :Task, "build:win32:standalone", %w[pkg/test_0_1_WIN32_EXE] ],

          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_0_1_WIN32_EXE", source_files ],
          [ :FileTask, "pkg/test_0_1_WIN32_EXE.7z", %w[pkg/test_0_1_WIN32_EXE] ],
      ]

      tasks.each do |type, name, prerequisites|
        asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
        asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
      end

      asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
    end

    context "generate folder + 7z" do
      hookup { Rake::Task["package:win32:standalone:7z"].invoke }

      asserts("readme copied to folder") { File.read("pkg/test_0_1_WIN32_EXE/README.txt") == File.read("README.txt") }
      asserts("folder includes links") { File.read("pkg/test_0_1_WIN32_EXE/Website.url") == link_file }
      asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32_EXE/test.exe") > 2**20 }
      asserts("archive created") { File.exists? "pkg/test_0_1_WIN32_EXE.7z" }
      asserts("archive contains expected files") { `7z l pkg/test_0_1_WIN32_EXE.7z` =~ /3 files, 1 folders/m }
    end
  end
end