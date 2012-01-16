require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::OsxApp do
  setup { Relapse::Builders::OsxApp.new new_project }

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  context "no wrapper" do
    hookup do
      topic.url = "org.frog.fish"
    end
    asserts(:generate_tasks).raises RuntimeError
  end

  context "invalid wrapper" do
    hookup do
      topic.url = "org.frog.fish"
      topic.wrapper = "whatever"
    end

    asserts(:generate_tasks).raises RuntimeError
  end

  context "valid" do
    hookup do
      topic.url = "org.frog.fish"
      topic.wrapper = "../../../osx_app/RubyGosu App.app"
      topic.generate_tasks
    end

    asserts(:folder_suffix).equals "OSX"
    asserts(:app_name).equals "Test App.app"
    asserts(:url).equals "org.frog.fish"
    asserts(:wrapper).equals "../../../osx_app/RubyGosu App.app"

    context "tasks" do
      tasks = [
          [ :Task, "build:osx:app", %w[pkg/test_app_0_1_OSX] ],
          [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
          [ :FileCreationTask, "pkg/test_app_0_1_OSX", source_files + ["../../../osx_app/RubyGosu App.app"]],
      ]

      test_tasks tasks
    end
  end
end