require File.expand_path("helper", File.dirname(__FILE__))

require 'fileutils'

# Change directory into the project, since that is where we work from normally.
Dir.chdir File.expand_path("../test_project", __FILE__)

module ReleasePackager
  context Project do
    helper(:source_files) { %w[bin/test lib/test.rb lib/test/stuff.rb README.txt] }

    #setup { FileUtils.rm_r "pkg" if File.exists? "pkg" }
    teardown { Rake::Task.clear }

    context "default" do
      setup { Project.new }

      # Defaults are mostly nil.
      asserts(:name).nil
      asserts(:underscored_name).nil
      asserts(:ocra_parameters).nil
      asserts(:version).nil
      asserts(:executable).nil
      asserts(:license).nil
      asserts(:icon).nil
      asserts(:installer_group).nil
      asserts(:files).equals []
      asserts(:verbose?).equals true
      asserts(:readme).nil

      asserts(:output_path).equals "pkg"
      asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

      asserts("attempting to generate tasks without any outputs") { topic.generate_tasks }.raises(RuntimeError)

      asserts(:add_compression, :zip).equals :zip
      asserts(:add_compression, :unknown).raises(ArgumentError, /unsupported compression/i)

      asserts(:add_output, :source).equals :source
      asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)
    end

    context "defined" do
      setup do
        Project.new do |p|
          p.name = "Test Project - (2a)"
          p.version = "v0.1.5"

          p.add_compression :"7z"
          p.add_compression :zip

          p.add_output :source
          p.add_output :win32_standalone

          p.files = source_files
        end
      end

      asserts(:name).equals "Test Project - (2a)"
      asserts(:underscored_name).equals "test_project_2a"
      asserts(:executable).equals "bin/test_project_2a"
      asserts(:folder_base).equals "pkg/test_project_2a_v0_1_5"
    end

    context "generating" do
      setup { Project.new }

      hookup do
        topic.name = "Test"
        topic.version = "0.1"
        topic.files = source_files
        topic.ocra_parameters = "--no-enc"
        topic.readme = "README.txt"
      end

      context "source as zip" do
        hookup do
          topic.add_output :source
          topic.add_compression :zip
        end

        should("create all necessary tasks") do
          [
              [ :task,      { "package" => %w[package:source] } ],
              [ :task,      { "package:source" => %w[package:source:zip] } ],
              [ :task,      { "package:source:zip" => "pkg/test_0_1_SOURCE.zip" } ],

              [ :task,      { "build" => %w[build:source] } ],
              [ :task,      { "build:source" => "pkg/test_0_1_SOURCE" } ],

              [ :file,      { "pkg/test_0_1_SOURCE" => source_files } ],
              [ :file,      { "pkg/test_0_1_SOURCE.zip" => "pkg/test_0_1_SOURCE" } ],
          ].each do |method, result|
            mock(topic, method).with(result)
          end

          topic.generate_tasks
        end

        context "generate folder + zip" do
          hookup do
            topic.generate_tasks
            Rake::Task["package:source:zip"].invoke
          end

          asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_SOURCE/#{f}") == File.read(f) } }
          asserts("archive created") { File.size("pkg/test_0_1_SOURCE.zip") > 0}
          asserts("archive contains expected files") { `7z l pkg/test_0_1_SOURCE.zip` =~ /4 files, 4 folders/m }
        end
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
          asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32_INSTALLER/test_setup.exe") > 2**20 }
          asserts("archive created") { File.exists? "pkg/test_0_1_WIN32_INSTALLER.zip" }
          asserts("archive contains expected files") { `7z l pkg/test_0_1_WIN32_INSTALLER.zip` =~ /2 files, 1 folders/m }
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
          asserts("executable created in folder and is of reasonable size") { File.size("pkg/test_0_1_WIN32_EXE/test.exe") > 2**20 }
          asserts("archive created") { File.exists? "pkg/test_0_1_WIN32_EXE.7z" }
          asserts("archive contains expected files") { `7z l pkg/test_0_1_WIN32_EXE.7z` =~ /2 files, 1 folders/m }
        end
      end
    end
  end
end