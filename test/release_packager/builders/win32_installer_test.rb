require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

context ReleasePackager::Builders::Win32Installer do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup { Dir.chdir project_path }

  context "win32 installer as zip" do
    hookup do
      topic.add_output :win32_installer
      topic.add_archive :zip
      topic.generate_tasks
    end

    context "tasks" do
      tasks = [
          [ :Task, "package", %w[package:win32] ],
          [ :Task, "package:win32", %w[package:win32:installer] ],
          [ :Task, "package:win32:installer", %w[package:win32:installer:zip] ],
          [ :Task, "package:win32:installer:zip", %w[pkg/test_0_1_WIN32_INSTALLER.zip] ],

          [ :Task, "build", %w[build:win32] ],
          [ :Task, "build:win32", %w[build:win32:installer] ],
          [ :Task, "build:win32:installer", %w[pkg/test_0_1_WIN32_INSTALLER] ],

          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_0_1_WIN32_INSTALLER", source_files ],
          [ :FileTask, "pkg/test_0_1_WIN32_INSTALLER.zip", %w[pkg/test_0_1_WIN32_INSTALLER] ],
      ]

      tasks.each do |type, name, prerequisites|
        asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
        asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
      end

      asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
    end

    context "generate folder + zip" do
      hookup { Rake::Task["package:win32:installer:zip"].invoke }

      asserts("readme copied to folder") { File.read("pkg/test_0_1_WIN32_INSTALLER/README.txt") == File.read("README.txt") }
      asserts("folder includes links") { File.read("pkg/test_0_1_WIN32_INSTALLER/Website.url") == link_file }
      asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32_INSTALLER/test_setup.exe") > 2**20 }
      asserts("archive created") { File.exists? "pkg/test_0_1_WIN32_INSTALLER.zip" }
      asserts("archive contains expected files") { `7z l pkg/test_0_1_WIN32_INSTALLER.zip` =~ /3 files, 1 folders/m }
    end
  end
end