require File.expand_path("helpers/helper", File.dirname(__FILE__))
require 'net/github-upload' # Because this isn't otherwise loaded until it is needed.

context Releasy::Deployers::Github do
  setup do
    stub(Kernel, :`).with("git config github.user").returns "test_user"
    stub(Kernel, :`).with("git config github.token").returns "0" * 32

    Releasy::Deployers::Github.new new_project
  end

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:type).equals :github
  asserts(:user).equals "test_user"
  asserts(:token).equals "0" * 32
  asserts(:description).equals "Test App 0.1"

  context "repository not configured" do
    setup do
      mock(Kernel, :`).with("git config remote.origin.url").returns { raise Errno::ENOENT }

      Releasy::Deployers::Github.new new_project
    end

    asserts(:repository).equals "test_app"
  end

  context "repository configured" do
    setup do
      mock(Kernel, :`).with("git config remote.origin.url").returns "git@github.com:test_user/test-app.git"

      Releasy::Deployers::Github.new new_project
    end

    asserts(:repository).equals "test-app"
  end

  context "user not configured" do
    setup do
      mock(Kernel, :`).with("git config github.user").returns { raise Errno::ENOENT }
      mock(Kernel, :`).with("git config github.token").returns "0" * 32

      Releasy::Deployers::Github.new new_project
    end

    asserts(:user).nil

    asserts(:deploy, "file").raises Releasy::ConfigError, /#user must be set manually if it is not configured on the system/
  end

  context "token not configured" do
    setup do
      mock(Kernel, :`).with("git config github.user").returns "test_user"
      mock(Kernel, :`).with("git config github.token").returns { raise Errno::ENOENT }

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
      should "upload the file if it doesn't exist on the server" do
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => false, :upload_timeout => 3600
        end

        topic.send :deploy, "file.zip"

        true
      end

      should "give a warning if the file already exists and not in replacement mode" do
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => false, :upload_timeout => 3600 do
            raise "file 'file.zip' is already uploaded. please try different name"
          end
        end
        mock(topic).warn "Skipping 'file.zip' as it is already uploaded. Use #replace! to force uploading"

        topic.send :deploy, "file.zip"

        true
      end

      asserts "errors other than file already exists" do
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => false, :upload_timeout => 3600 do
            raise "something else happened"
          end
        end

        dont_allow(topic).warn anything

        topic.send :deploy, "file.zip"
      end.raises RuntimeError, "something else happened"

      should "upload the file if it exists on the server and in replacement mode" do
        mock(Net::GitHub::Upload).new :login => "test_user", :token => "0" * 32 do
          mock!.upload :repos => "test_app", :file => "file.zip", :description => "Test App 0.1", :replace => true, :upload_timeout => 3600
        end

        topic.replace!
        topic.send :deploy, "file.zip"

        true
      end
    end
  end
end