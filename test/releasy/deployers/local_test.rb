require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Releasy::Deployers::Local do
  setup do
    Releasy::Deployers::Local.new new_project
  end

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:type).equals :local
  asserts(:path).nil
  asserts(:path=, 5).raises TypeError, /path must be a String/

  context "#path=" do
    hookup { topic.path = "fish" }
    asserts(:path).equals "fish"
  end

  context "valid" do
    context "#generate_tasks" do
      hookup { topic.send :generate_tasks, "source:7z", "SOURCE.7z", ".7z" }
      tasks = [
          [ :Task, "deploy:source:7z:local", %w[package:source:7z] ],
      ]

      test_tasks tasks
    end

    context "#deploy" do
      context "without #path" do
        asserts(:deploy, "file.zip").raises Releasy::ConfigError, /#path must be set/
      end

      context "valid" do
        hookup { topic.path = "fish" }

        should "create directory and copy file if directory doesn't exist" do
          stub(File).exists?("fish").returns false
          stub(File).exists?("fish/file.zip").returns false

          mock(topic).mkdir_p("fish", :verbose => false)
          mock(topic).cp("file.zip", "fish", :verbose => false, :force => false)
          topic.send :deploy, "file.zip"

          true
        end

        should "copy file to directory if directory exists" do
          stub(File).exists?("fish").returns true
          stub(File).exists?("fish/file.zip").returns false

          mock(topic).cp("file.zip", "fish", :verbose => false, :force => false)
          topic.send :deploy, "file.zip"

          true
        end

        should "copy file forcefully if destination file is older" do
          stub(File).exists?("fish").returns true
          stub(File).exists?("fish/file.zip").returns true
          stub(File).ctime("fish/file.zip").returns 0
          stub(File).ctime("file.zip").returns 1

          mock(topic).cp("file.zip", "fish", :verbose => false, :force => true)
          topic.send :deploy, "file.zip"

          true
        end

        should "not copy file if destination file is not older" do
          stub(File).exists?("fish").returns true
          stub(File).exists?("fish/file.zip").returns true
          stub(File).ctime("fish/file.zip").returns 1
          stub(File).ctime("file.zip").returns 1

          dont_allow(topic).cp
          mock(topic).warn "Skipping 'file.zip' because it already exists in 'fish'"
          topic.send :deploy, "file.zip"

          true
        end
      end
    end

  end
end