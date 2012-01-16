require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

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

    asserts(:folder).equals "pkg/test_app_0_1_SOURCE"
    asserts(:folder_suffix).equals "SOURCE"

    context "tasks" do
      tasks = [
          [ :Task, "build:source", %w[pkg/test_app_0_1_SOURCE] ],
          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_app_0_1_SOURCE", source_files ],
      ]

      test_tasks tasks
    end
  end
end
