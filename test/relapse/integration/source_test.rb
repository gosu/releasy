require File.expand_path("../../teststrap", File.dirname(__FILE__))

folder = 'pkg/test_app_0_1_SOURCE'


context "Source in all formats" do
  setup do
    Relapse::Project.new do |p|
      p.name = "Test App"
      p.version = "0.1"
      p.files = source_files
      p.verbose = false

      p.add_output :source do |o|
        o.add_archive_format :dmg
        o.add_archive_format :exe
        o.add_archive_format :zip
        o.add_archive_format :"7z"
      end
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

  active_builders_valid

  context "tasks" do
    tasks = [
        [ :Task, "package", %w[package:source] ],
        [ :Task, "package:source", %w[package:source:dmg package:source:7z package:source:exe package:source:tar_gz package:source:tar_bz2 package:source:zip] ],
        [ :Task, "package:source:dmg", ["#{folder}.dmg"] ],
        [ :Task, "package:source:7z", ["#{folder}.7z"] ],
        [ :Task, "package:source:exe", ["#{folder}.exe"] ],
        [ :Task, "package:source:tar_gz", ["#{folder}.tar.gz"] ],
        [ :Task, "package:source:tar_bz2", ["#{folder}.tar.bz2"] ],
        [ :Task, "package:source:zip", ["#{folder}.zip"] ],

        [ :Task, "build", %w[build:source] ],
        [ :Task, "build:source", [folder] ],

        [ :FileCreationTask, "pkg", [] ], # byproduct of using #directory
        [ :FileCreationTask, folder, source_files ],
        [ :FileTask, "#{folder}.dmg", [folder] ],
        [ :FileTask, "#{folder}.7z", [folder] ],
        [ :FileTask, "#{folder}.exe", [folder] ],
        [ :FileTask, "#{folder}.tar.gz", [folder] ],
        [ :FileTask, "#{folder}.tar.bz2", [folder] ],
        [ :FileTask, "#{folder}.zip", [folder] ],
    ]

    test_tasks tasks
  end

  if osx_platform?
    # TODO: Test this better?
    context "dmg" do
      hookup { Rake::Task["package:source:dmg"].invoke }

      asserts("archive created") { File.size("#{folder}.dmg") > 0}
    end
  end

  context "exe" do
    hookup { Rake::Task["package:source:exe"].invoke }

    asserts("archive created") { File.size("#{folder}.exe") > 0}
  end

  context "tar.gz" do
    hookup { Rake::Task["package:source:tar_gz"].invoke }

    asserts("archive created") { File.size("#{folder}.tar.gz") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tgzip #{folder}.tar.gz | 7z l -si -bd -ttar` =~ /5 files, 4 folders/m }
  end

  context "tar.bz2" do
    hookup { Rake::Task["package:source:tar_bz2"].invoke }

    asserts("archive created") { File.size("#{folder}.tar.bz2") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tbzip2 #{folder}.tar.bz2 | 7z l -si -bd -ttar` =~ /5 files, 4 folders/m }
  end

  context "zip" do
    hookup { Rake::Task["package:source:zip"].invoke }

    asserts("archive created") { File.size("#{folder}.zip") > 0}
    asserts("archive contains expected files") { `7z l -bd -tzip #{folder}.zip` =~ /5 files, 4 folders/m }
  end

  context "7z" do
    hookup { Rake::Task["package:source:7z"].invoke }

    asserts("archive created") { File.size("#{folder}.7z") > 0}
    asserts("archive contains expected files") { `7z l -bd -t7z #{folder}.7z` =~ /5 files, 4 folders/m }
  end
end
