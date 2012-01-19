require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = "pkg/test_app_0_1_SOURCE"
context Relapse::Builders::Source do
  setup { Relapse::Builders::Source.new new_project }

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  context "valid" do
    hookup do
      topic.generate_tasks
    end

    asserts(:folder).equals folder
    asserts(:folder_suffix).equals "SOURCE"

    context "tasks" do
      tasks = [
          [ :Task, "build:source", %w[pkg/test_app_0_1_SOURCE] ],
          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, folder, source_files ],
      ]

      test_tasks tasks
    end

    context "generate folder" do
      hookup { Rake::Task["build:source"].invoke }

      asserts("files copied to folder") { source_files.all? {|f| File.read("#{folder}/#{f}") == File.read(f) } }
      asserts("program output") { %x[ruby "#{folder}/bin/test_app"] }.equals "test run!\n"
    end
  end
end
