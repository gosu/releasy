require File.expand_path("teststrap", File.dirname(__FILE__))

context ReleasePackager::Osx do
  setup { ReleasePackager::Project.new }
  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path

    topic.name = "Test"
    topic.version = "0.1"
    topic.files = source_files
    topic.readme = "README.txt"

    topic.add_output :osx_app
    topic.add_compression :zip
  end
end