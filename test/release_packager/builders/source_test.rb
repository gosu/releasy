require File.expand_path("../../teststrap", File.dirname(__FILE__))

context ReleasePackager::Builders::Source do
  setup do
    ReleasePackager::Project.new do |p|
      p.name = "Test"
      p.version = "0.1"
      p.files = source_files
      p.readme = "README.txt"

      p.add_output :source
      p.add_archive :zip
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
        [ :Task, "package", %w[package:source] ],
        [ :Task, "package:source", %w[package:source:zip] ],
        [ :Task, "package:source:zip", %w[pkg/test_0_1_SOURCE.zip] ],

        [ :Task, "build", %w[build:source] ],
        [ :Task, "build:source", %w[pkg/test_0_1_SOURCE] ],

        [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
        [ :FileCreationTask, "pkg/test_0_1_SOURCE", source_files ],
        [ :FileTask, "pkg/test_0_1_SOURCE.zip", %w[pkg/test_0_1_SOURCE] ],
    ]

    tasks.each do |type, name, prerequisites|
      asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
      asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
    end

    asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
  end

  context "generate folder + zip" do
    hookup { Rake::Task["package:source:zip"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_0_1_SOURCE.zip") > 0}
    asserts("archive contains expected files") { `7z l pkg/test_0_1_SOURCE.zip` =~ /4 files, 4 folders/m }
  end
end
