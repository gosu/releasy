require File.expand_path("../teststrap", File.dirname(__FILE__))

# Change directory into the project, since that is where we work from normally.

# @author Bil Bas (Spooner)
context Relapse::Project do
  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  context "default" do
    setup { Relapse::Project.new }

    # Defaults are mostly nil.
    asserts(:name).nil
    asserts(:underscored_name).nil
    asserts(:version).nil
    asserts(:executable).nil
    asserts(:license).nil
    asserts(:icon).nil
    asserts(:files).empty
    asserts(:verbose?).equals true
    asserts(:readme).nil
    asserts(:links).equals Hash.new

    asserts(:output_path).equals "pkg"
    asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

    asserts("attempting to generate tasks without any outputs") { topic.generate_tasks }.raises(RuntimeError)

    asserts(:active_builders).empty
    asserts(:add_output, :source).kind_of Relapse::Builders::Source
    asserts(:active_builders).size 1
    asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)

    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.empty
    asserts(:add_archive_format, :zip).kind_of Relapse::Archivers::Zip
    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.size 1
    asserts(:add_archive_format, :unknown).raises(ArgumentError, /unsupported archive/i)
  end

  context "defined" do
    setup do
      Relapse::Project.new do |p|
        p.name = "Test Project - (2a)"
        p.version = "v0.1.5"

        p.add_archive_format :"7z"
        p.add_archive_format :zip

        p.add_output :source
        p.add_output :osx_app do |o|
          o.add_archive_format :tar_gz
          o.wrapper = app_wrapper
          o.url = "org.url.app"
          o.gems = Bundler.setup.gems
        end
        p.add_output :win32_standalone do |o|
          o.ocra_parameters = "--no-enc"
        end

        p.files = source_files

        p.add_link "www.frog.com", "Frog"
        p.add_link "www2.fish.com", "Fish"
      end
    end

    asserts(:name).equals "Test Project - (2a)"
    asserts(:underscored_name).equals "test_project_2a"
    asserts(:executable).equals "bin/test_project_2a"
    asserts(:folder_base).equals "pkg/test_project_2a_v0_1_5"
    asserts(:links).equals "www.frog.com" => "Frog", "www2.fish.com" => "Fish"

    asserts(:active_builders).size(windows? ? 3 : 2)
    asserts("source active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :source }) }.size 2
    asserts("osx app active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :osx_app }) }.size 3
    if windows?
      asserts("win32 standalone active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :win32_standalone }) }.size 2
    end
  end
end