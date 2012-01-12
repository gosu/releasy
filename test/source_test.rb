require File.expand_path("teststrap", File.dirname(__FILE__))

context ReleasePackager::Source do
  setup do
    ReleasePackager::Project.new do |p|
      p.name = "Test"
      p.version = "0.1"
      p.files = source_files
      p.readme = "README.txt"

      p.add_output :source
      p.add_compression :zip
    end
  end

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  context "tasks" do
    tasks = [
        [ "package", %w[package:source] ],
        [ "package:source", %w[package:source:zip] ],
        [ "package:source:zip", %w[pkg/test_0_1_SOURCE.zip] ],

        [ "build", %w[build:source] ],
        [ "build:source", %w[pkg/test_0_1_SOURCE] ],

        [ "pkg", [] ], # byproduct of using #directory
        [ "pkg/test_0_1_SOURCE", source_files ],
        [ "pkg/test_0_1_SOURCE.zip", %w[pkg/test_0_1_SOURCE] ],
    ]

    tasks.each do |name, prerequisites|
      asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
    end

    asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[0]] }).empty? }
  end

  context "generate folder + zip" do
    hookup { Rake::Task["package:source:zip"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_0_1_SOURCE.zip") > 0}
    asserts("archive contains expected files") { `7z l pkg/test_0_1_SOURCE.zip` =~ /4 files, 4 folders/m }
  end
end
