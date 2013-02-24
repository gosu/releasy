require File.expand_path("../../teststrap", File.dirname(__FILE__))

folder = File.join(output_path, "test_app_0_1_SOURCE")

def md5_created(extension)
  file = "#{File.join(output_path, "test_app_0_1_SOURCE")}#{extension}.MD5"
  asserts("MD5 file created") { File.exists?(file) }
  asserts("MD5 file contents sensible") { File.read(file) =~ /^[0-9a-f]{32}$/ }
end

_output_path = output_path # Needed to get to work in the DSLWrapper.
context "Source in all formats" do
  setup do
    Releasy::Project.new do
      name "Test App"
      version "0.1"
      files source_files
      output_path _output_path
      create_md5s

      add_build :source do
        add_package :dmg
        add_package :exe
        add_package :zip
        add_package :"7z"
      end

      add_package :tar_gz
      add_package :tar_bz2

      add_deploy :local
    end
  end

  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  helper(:contents_description) { /#{source_files.size} files, 4 folders/m }
  helper(:null_file) { Gem.win_platform? ? "NUL" : "/dev/null" }

  active_builders_valid

  context "tasks" do
    tasks = [
        [ :Task, "deploy", %w[deploy:source] ],
        [ :Task, "deploy:local", %w[deploy:source:local] ],
        [ :Task, "deploy:source", %w[deploy:source:local] ],
        [ :Task, "deploy:source:local", %w[deploy:source:dmg:local deploy:source:7z:local deploy:source:exe:local deploy:source:tar_gz:local deploy:source:tar_bz2:local deploy:source:zip:local] ],
        [ :Task, "deploy:source:dmg", %w[deploy:source:dmg:local] ],
        [ :Task, "deploy:source:dmg:local", %w[package:source:dmg] ],
        [ :Task, "deploy:source:7z", %w[deploy:source:7z:local] ],
        [ :Task, "deploy:source:7z:local", %w[package:source:7z] ],
        [ :Task, "deploy:source:exe", %w[deploy:source:exe:local] ],
        [ :Task, "deploy:source:exe:local", %w[package:source:exe] ],
        [ :Task, "deploy:source:tar_gz", %w[deploy:source:tar_gz:local] ],
        [ :Task, "deploy:source:tar_gz:local", %w[package:source:tar_gz] ],
        [ :Task, "deploy:source:tar_bz2", %w[deploy:source:tar_bz2:local] ],
        [ :Task, "deploy:source:tar_bz2:local", %w[package:source:tar_bz2] ],
        [ :Task, "deploy:source:zip", %w[deploy:source:zip:local] ],
        [ :Task, "deploy:source:zip:local", %w[package:source:zip] ],

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

        [ :FileTask, '..', [] ],
        [ :FileTask, output_path, [] ], # byproduct of using #directory
        [ :FileTask, folder, source_files ],
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

  context ".exe" do
    hookup { Rake::Task["package:source:exe"].invoke }

    asserts("archive created") { File.size("#{folder}.exe") > 0}
    md5_created ".exe"
  end

  context ".tar.gz" do
    hookup { Rake::Task["package:source:tar_gz"].invoke }

    asserts("archive created") { File.size("#{folder}.tar.gz") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tgzip #{folder}.tar.gz 2>#{null_file} | 7z l -si -bd -ttar` =~ contents_description }
    md5_created ".tar.gz"
  end

  context ".tar.bz2" do
    hookup { Rake::Task["package:source:tar_bz2"].invoke }

    asserts("archive created") { File.size("#{folder}.tar.bz2") > 0}
    asserts("archive contains expected files") { `7z x -so -bd -tbzip2 #{folder}.tar.bz2 2>#{null_file} | 7z l -si -bd -ttar` =~ contents_description }
    md5_created ".tar.bz2"
  end

  context ".zip" do
    hookup { Rake::Task["package:source:zip"].invoke }

    asserts("archive created") { File.size("#{folder}.zip") > 0}
    asserts("archive contains expected files") { `7z l -bd -tzip #{folder}.zip` =~ contents_description }
    md5_created ".zip"
  end

  context ".7z" do
    hookup { Rake::Task["package:source:7z"].invoke }

    asserts("archive created") { File.size("#{folder}.7z") > 0}
    asserts("archive contains expected files") { `7z l -bd -t7z #{folder}.7z` =~ contents_description }
    md5_created ".7z"
  end
end
