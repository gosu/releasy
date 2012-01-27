require File.expand_path("helpers/helper", File.dirname(__FILE__))


context Releasy::Deployers::Github do
  setup do
    any_instance_of Releasy::Deployers::Github do |github|
      stub(github, :`).with("git config github.user").returns "test_user"
      stub(github, :`).with("git config github.token").returns "0" * 32
    end

    Releasy::Deployers::Github.new new_project
  end

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:user).equals "test_user"
  asserts(:token).equals "0" * 32
  asserts(:description).equals "Test App 0.1"

  context "repository not configured" do
    setup do
      any_instance_of Releasy::Deployers::Github do |github|
        mock(github, :`).with("git config remote.origin.url").returns { raise Errno::ENOENT }
      end

      Releasy::Deployers::Github.new new_project
    end

    asserts(:repository).equals "test_app"
  end

  context "repository configured" do
    setup do
      any_instance_of Releasy::Deployers::Github do |github|
        mock(github, :`).with("git config remote.origin.url").returns "git@github.com:test_user/test-app.git"
      end

      Releasy::Deployers::Github.new new_project
    end

    asserts(:repository).equals "test-app"
  end

  context "user not configured" do
    setup do
      any_instance_of Releasy::Deployers::Github do |github|
        mock(github, :`).with("git config github.user").returns { raise Errno::ENOENT }
        mock(github, :`).with("git config github.token").returns "0" * 32
      end

      Releasy::Deployers::Github.new new_project
    end

    asserts(:user).nil

    asserts(:deploy, "file").raises Releasy::ConfigError, /#user must be set manually if it is not configured on the system/
  end

  context "token not configured" do
    setup do
      any_instance_of Releasy::Deployers::Github do |github|
        mock(github, :`).with("git config github.user").returns "test_user"
        mock(github, :`).with("git config github.token").returns { raise Errno::ENOENT }
      end
      Releasy::Deployers::Github.new new_project
    end

    asserts(:token).nil

    asserts(:deploy, "file").raises Releasy::ConfigError, /#token must be set manually if it is not configured on the system/
  end


  context "valid" do
    context "#generate_tasks" do
      hookup { topic.send :generate_tasks, "source:7z", "SOURCE.7z", ".7z" }
      tasks = [
          [ :Task, "deploy:source:7z:github", %w[package:source:7z] ],
      ]

      test_tasks tasks
    end

    context "#deploy" do
      helper(:stub_file_size) { stub(File).size("file.zip").returns 1000 }

      should "expect an Net::GitHub::Upload to be created and used to upload" do
        stub_file_size
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => false
        end

        topic.send :deploy, "file.zip"

        true
      end

      should "expect an Net::GitHub::Upload to be created and exit (not forcing replacement and file already exists)" do
        stub_file_size
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => false do
            raise "file already exists"
          end
        end

        mock(topic).exit(1)

        topic.send :deploy, "file.zip"

        true
      end

      should "expect an Net::GitHub::Upload to be created and used to upload (forcing replacement)" do
        stub_file_size
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => true
        end

        topic.replace!
        topic.send :deploy, "file.zip"

        true
      end
    end
  end
end