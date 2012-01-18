require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/win32", File.dirname(__FILE__))

folder = 'pkg/test_app_0_1_WIN32_EXE'

context "win32 standalone as 7z" do
  setup { win32_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
    topic.add_output :win32_standalone do |o|
      o.ocra_parameters = "--no-enc"
      o.executable_type = :console
      o.icon = "test_app.ico"
    end
    topic.add_archive_format :"7z"
  end

  active_builders_valid

  if Gem.win_platform?
    context "on Windows" do
      hookup { topic.generate_tasks }

      tasks = [
          [ :Task, "package", %w[package:win32] ],
          [ :Task, "package:win32", %w[package:win32:standalone] ],
          [ :Task, "package:win32:standalone", %w[package:win32:standalone:7z] ],
          [ :Task, "package:win32:standalone:7z", ["#{folder}.7z"] ],

          [ :Task, "build", %w[build:win32] ],
          [ :Task, "build:win32", %w[build:win32:standalone] ],
          [ :Task, "build:win32:standalone", [folder] ],

          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, folder, source_files ],
          [ :FileTask, "#{folder}.7z", [folder] ],
      ]

      test_tasks tasks

      context "generate folder + 7z" do
        hookup do
          redirect_bundler_gemfile { Rake::Task["build:win32:standalone"].invoke }
        end

        asserts("readme copied to folder") { File.read("#{folder}/README.txt") == File.read("README.txt") }
        asserts("license copied to folder") { File.read("#{folder}/LICENSE.txt") == File.read("LICENSE.txt") }
        asserts("folder includes link") { File.read("#{folder}/Relapse website.url") == link_file }
        asserts("executable created in folder and is of reasonable size") { File.size("#{folder}/test_app.exe") > 2**20 }
        asserts("program output") { redirect_bundler_gemfile { %x[#{folder}/test_app.exe] } }.equals "test run!\n"
      end
    end
  else
    context "NOT on Windows" do
      asserts(:active_builders).empty
    end
  end
end