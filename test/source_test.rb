require File.expand_path("teststrap", File.dirname(__FILE__))

context ReleasePackager::Source do
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

    topic.add_output :source
    topic.add_compression :zip
  end

  should("create all necessary tasks") do
    [
        [ :task,      { "package" => %w[package:source] } ],
        [ :task,      { "package:source" => %w[package:source:zip] } ],
        [ :task,      { "package:source:zip" => "pkg/test_0_1_SOURCE.zip" } ],

        [ :task,      { "build" => %w[build:source] } ],
        [ :task,      { "build:source" => "pkg/test_0_1_SOURCE" } ],

        [ :file,      { "pkg/test_0_1_SOURCE" => source_files } ],
        [ :file,      { "pkg/test_0_1_SOURCE.zip" => "pkg/test_0_1_SOURCE" } ],
    ].each do |method, result|
      mock(topic, method).with(result)
    end

    topic.generate_tasks
  end

  context "generate folder + zip" do
    hookup do
      topic.generate_tasks
      Rake::Task["package:source:zip"].invoke
    end

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_0_1_SOURCE.zip") > 0}
    asserts("archive contains expected files") { `7z l pkg/test_0_1_SOURCE.zip` =~ /4 files, 4 folders/m }
  end
end
