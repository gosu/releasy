require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Releasy::Deployers::Rsync do
  setup do
    Releasy::Deployers::Rsync.new new_project
  end

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:type).equals :rsync
  asserts(:destination).nil
  asserts(:destination=, 5).raises TypeError, /destination must be a String/
  asserts(:options).equals '-glpPrtvz'
  asserts(:options=, 5).raises TypeError, /options must be a String/
  asserts(:deploy, "file.zip").raises Releasy::ConfigError, /#destination must be set/

  context "#destination=" do
    hookup { topic.destination = "fish:www/frog" }
    asserts(:destination).equals "fish:www/frog"
  end

  context "#options=" do
    hookup { topic.options = "-frog" }
    asserts(:options).equals "-frog"
  end

  context "valid" do
    context "#generate_tasks" do
      hookup { topic.send :generate_tasks, "source:7z", "SOURCE.7z", ".7z" }
      tasks = [
          [ :Task, "deploy:source:7z:rsync", %w[package:source:7z] ],
      ]

      test_tasks tasks
    end

    should "call rsync correctly" do
      mock(IO).popen(%[rsync -xyz "#{File.expand_path "pkg/x.zip"}" "fish:www/frog"]).yields StringIO.new("done")

      topic.options = "-xyz"
      topic.destination = "fish:www/frog"

      topic.send :deploy, "pkg/x.zip"

      true
    end
  end
end