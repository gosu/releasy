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
    asserts(:files).empty
    asserts(:exposed_files).empty
    asserts(:verbose?).equals true
    asserts(:links).equals Hash.new
    asserts(:to_s).equals "<Relapse::Project>"

    asserts(:output_path).equals "pkg"
    asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

    asserts("attempting to generate tasks without any outputs") { topic.generate_tasks }.raises Relapse::ConfigError, /must specify at least one valid output/i

    asserts(:active_builders).empty
    asserts(:add_output, :source).kind_of Relapse::Builders::Source
    asserts(:active_builders).size 1
    asserts(:add_output, :source).raises(Relapse::ConfigError, /already have output :source/i)
    asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)

    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.empty
    asserts(:add_archive_format, :zip).kind_of Relapse::Archivers::Zip
    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.size 1
    asserts(:add_archive_format, :zip).raises(Relapse::ConfigError, /already have archive format :zip/i)
    asserts(:add_archive_format, :unknown).raises(ArgumentError, /unsupported archive/i)
  end

  context "defined" do
    setup do
      Relapse::Project.new do
        name "Test Project - (2a)"
        version "v0.1.5"

        add_archive_format :"7z"
        add_archive_format :zip

        add_output :source
        add_output :osx_app do
          add_archive_format :tar_gz
          wrapper osx_app_wrapper
          url "org.url.app"
          gemspecs Bundler.setup.gems
        end
        add_output :win32_standalone do
          ocra_parameters "--no-enc"
        end

        files source_files

        add_link "www.frog.com", "Frog"
        add_link "www2.fish.com", "Fish"
      end
    end

    asserts(:to_s).equals %[<Relapse::Project Test Project - (2a) v0.1.5>]
    asserts(:name).equals "Test Project - (2a)"
    asserts(:underscored_name).equals "test_project_2a"
    asserts(:version).equals "v0.1.5"
    asserts(:files).same_elements source_files
    asserts(:underscored_version).equals "v0_1_5"
    asserts(:executable).equals "bin/test_project_2a"
    asserts(:folder_base).equals "pkg/test_project_2a_v0_1_5"
    asserts(:links).equals "www.frog.com" => "Frog", "www2.fish.com" => "Fish"

    asserts(:active_builders).size(Gem.win_platform? ? 3 : 2)
    asserts("source active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :source }) }.size 2
    asserts("osx app active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :osx_app }) }.size 3
    if Gem.win_platform?
      asserts("win32 standalone active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :win32_standalone }) }.size 2
    end

    asserts "add_output yields an instance_eval-ed Relapse::Dsl" do
      correct = false
      topic.add_output :win32_folder_from_wrapper do
        correct = (is_a?(Relapse::Dsl) and owner.is_a?(Relapse::Builders::Win32FolderFromWrapper))
      end
      correct
    end

    asserts "add_archive_format yields an instance_eval-ed Relapse::Dsl" do
      correct = false
      topic.add_archive_format :tar_gz do
        correct = (is_a?(Relapse::Dsl) and owner.is_a?(Relapse::Archivers::TarGzip))
      end
      correct
    end

    context "#generate_archive_tasks" do
      asserts(:generate_archive_tasks).equals { topic }

      should "call generate_tasks on all archivers" do
        topic.send(:active_builders).each do |builder|
          topic.send(:active_archivers, builder).each {|a| mock(a).generate_tasks(builder.type.to_s.sub('_', ':'), builder.folder) }
        end
        topic.send :generate_archive_tasks
      end
    end

    context "#generate_tasks" do
      asserts(:generate_tasks).equals { topic }

      should "call generate_tasks on all builders" do
        topic.send(:active_builders) {|b| mock(b).generate_tasks }
        topic.generate_tasks
      end

      should "call #generate_archive_tasks" do
        mock(topic).generate_archive_tasks
        topic.generate_tasks
      end
    end
  end
end