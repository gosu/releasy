require File.expand_path("teststrap", File.dirname(__FILE__))

context ReleasePackager::Osx do
  setup do
=begin
    ReleasePackager::Project.new do |p|
      p.name = "Test"
      p.version = "0.1"
      p.files = source_files
      p.readme = "README.txt"

      p.add_output :osx_app
      p.add_compression :zip
    end
=end
  end

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end
end