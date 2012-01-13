require File.expand_path("teststrap", File.dirname(__FILE__))

context ReleasePackager::Win32 do
  setup { ReleasePackager::Project.new }
  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  helper(:link_file) { "[InternetShortcut]\nURL=http://www.website.com\n" }

  hookup do
    Dir.chdir project_path

    topic.name = "Test"
    topic.version = "0.1"
    topic.files = source_files
    topic.ocra_parameters = "--no-enc"
    topic.readme = "README.txt"
    topic.add_link "http://www.website.com", "Website"
  end

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