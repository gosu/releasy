require File.expand_path("../../teststrap", File.dirname(__FILE__))

context ReleasePackager::Builders::Source do
  setup do
    ReleasePackager::Project.new do |p|
      p.name = "Test App"
      p.version = "0.1"
      p.files = source_files
      p.readme = "README.txt"

      p.add_output :source
      p.add_archive_format :tar_gz
      p.add_archive_format :tar_bz2
    end
  end

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  test_active_builders

  context "tasks" do
    tasks = [
        [ :Task, "package", %w[package:source] ],
        [ :Task, "package:source", %w[package:source:tar_gz package:source:tar_bz2] ],
        [ :Task, "package:source:tar_gz", %w[pkg/test_app_0_1_SOURCE.tar.gz] ],
        [ :Task, "package:source:tar_bz2", %w[pkg/test_app_0_1_SOURCE.tar.bz2] ],

        [ :Task, "build", %w[build:source] ],
        [ :Task, "build:source", %w[pkg/test_app_0_1_SOURCE] ],

        [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
        [ :FileCreationTask, "pkg/test_app_0_1_SOURCE", source_files ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.tar.gz", %w[pkg/test_app_0_1_SOURCE] ],
        [ :FileTask, "pkg/test_app_0_1_SOURCE.tar.bz2", %w[pkg/test_app_0_1_SOURCE] ],
    ]

    test_tasks tasks
  end

  context "generate folder + tar.gz" do
    hookup {Rake::Task["package:source:tar_gz"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_app_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_app_0_1_SOURCE.tar.gz") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tgzip pkg/test_app_0_1_SOURCE.tar.gz | 7z l -si -bd -ttar` =~ /4 files, 4 folders/m }
  end

  context "generate folder + tar.bz2" do
    hookup {Rake::Task["package:source:tar_bz2"].invoke }

    asserts("files copied to folder") { source_files.all? {|f| File.read("pkg/test_app_0_1_SOURCE/#{f}") == File.read(f) } }
    asserts("archive created") { File.size("pkg/test_app_0_1_SOURCE.tar.bz2") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tbzip2 pkg/test_app_0_1_SOURCE.tar.bz2 | 7z l -si -bd -ttar` =~ /4 files, 4 folders/m }
  end

  context "the builder itself" do
    setup { ReleasePackager::Builders::Source.new(topic) }

    asserts(:folder_suffix).equals "SOURCE"
  end
end
