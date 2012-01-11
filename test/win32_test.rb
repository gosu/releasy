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
      topic.add_compression :zip
    end

    should("create all necessary tasks") do
      [
          [ :task,      { "package" => %w[package:win32]} ],
          [ :task,      { "package:win32" => %w[package:win32:folder] } ],
          [ :task,      { "package:win32:folder" => %w[package:win32:folder:zip] } ],
          [ :task,      { "package:win32:folder:zip" => "pkg/test_0_1_WIN32.zip" } ],

          [ :task,      { "build" => %w[build:win32] } ],
          [ :task,      { "build:win32" => %w[build:win32:folder] } ],
          [ :task,      { "build:win32:folder" => "pkg/test_0_1_WIN32" } ],

          [ :file,      { "pkg/test_0_1_WIN32.zip" => "pkg/test_0_1_WIN32" } ],
          [ :file,      { "pkg/test_0_1_WIN32" => source_files } ],
      ].each do |method, result|
        mock(topic, method).with(result)
      end

      topic.generate_tasks
    end

    context "generate folder + zip" do
      hookup do
        topic.generate_tasks
        begin
          Rake::Task["package:win32:folder:zip"].invoke
        rescue
          # TODO: This prevents the whole test suite from breaking, but should be removed eventually.
        end
      end

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
      topic.add_compression :zip
    end

    should("create all necessary tasks") do
      [
          [ :task,      { "package" => %w[package:win32]} ],
          [ :task,      { "package:win32" => %w[package:win32:installer] } ],
          [ :task,      { "package:win32:installer" => %w[package:win32:installer:zip] } ],
          [ :task,      { "package:win32:installer:zip" => "pkg/test_0_1_WIN32_INSTALLER.zip" } ],

          [ :task,      { "build" => %w[build:win32] } ],
          [ :task,      { "build:win32" => %w[build:win32:installer] } ],
          [ :task,      { "build:win32:installer" => "pkg/test_0_1_WIN32_INSTALLER" } ],

          [ :file,      { "pkg/test_0_1_WIN32_INSTALLER.zip" => "pkg/test_0_1_WIN32_INSTALLER" } ],
          [ :file,      { "pkg/test_0_1_WIN32_INSTALLER" => source_files } ],
      ].each do |method, result|
        mock(topic, method).with(result)
      end

      topic.generate_tasks
    end

    context "generate folder + zip" do
      hookup do
        topic.generate_tasks
        Rake::Task["package:win32:installer:zip"].invoke
      end

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
      topic.add_compression :"7z"
    end

    should("create all necessary tasks") do
      [
          [ :task,      { "package" => %w[package:win32]} ],
          [ :task,      { "package:win32" => %w[package:win32:standalone] } ],
          [ :task,      { "package:win32:standalone" => %w[package:win32:standalone:7z] } ],
          [ :task,      { "package:win32:standalone:7z" => "pkg/test_0_1_WIN32_EXE.7z" } ],

          [ :task,      { "build" => %w[build:win32] } ],
          [ :task,      { "build:win32" => %w[build:win32:standalone] } ],
          [ :task,      { "build:win32:standalone" => "pkg/test_0_1_WIN32_EXE" } ],

          [ :file,      { "pkg/test_0_1_WIN32_EXE.7z" => "pkg/test_0_1_WIN32_EXE" } ],
          [ :file,      { "pkg/test_0_1_WIN32_EXE" => source_files } ],
      ].each do |method, result|
        mock(topic, method).with(result)
      end

      topic.generate_tasks
    end

    context "generate folder + 7z" do
      hookup do
        topic.generate_tasks
        Rake::Task["package:win32:standalone:7z"].invoke
      end

      asserts("readme copied to folder") { File.read("pkg/test_0_1_WIN32_EXE/README.txt") == File.read("README.txt") }
      asserts("folder includes links") { File.read("pkg/test_0_1_WIN32_EXE/Website.url") == link_file }
      asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32_EXE/test.exe") > 2**20 }
      asserts("archive created") { File.exists? "pkg/test_0_1_WIN32_EXE.7z" }
      asserts("archive contains expected files") { `7z l pkg/test_0_1_WIN32_EXE.7z` =~ /3 files, 1 folders/m }
    end
  end
end