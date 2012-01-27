require File.expand_path("../teststrap", File.dirname(__FILE__))

# Change directory into the project, since that is where we work from normally.

# @author Bil Bas (Spooner)
context Releasy::Project do
  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  context "default" do
    setup { Releasy::Project.new }

    # Defaults are mostly nil.
    asserts(:name).nil
    asserts(:underscored_name).nil
    asserts(:version).nil
    asserts(:description).nil
    asserts(:underscored_description).nil
    asserts(:executable).nil
    asserts(:files).empty
    asserts(:files).kind_of Rake::FileList
    asserts(:exposed_files).empty
    asserts(:exposed_files).kind_of Rake::FileList
    asserts(:verbose?).equals true
    asserts(:links).equals Hash.new
    asserts(:create_md5s?).equals false

    asserts(:to_s).equals "<Releasy::Project>"
    asserts(:output_path).equals "pkg"
    asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

    asserts("attempting to generate tasks without any outputs") { topic.send :generate_tasks }.raises Releasy::ConfigError, /must specify at least one valid output/i

    asserts(:active_builders).empty
    asserts(:add_build, :source).kind_of Releasy::Builders::Source
    asserts(:active_builders).size 1
    asserts(:add_build, :source).raises(Releasy::ConfigError, /already have output :source/i)
    asserts(:add_build, :unknown).raises(ArgumentError, /unsupported output/i)

    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.empty
    asserts(:add_archive, :zip).kind_of Releasy::Archivers::Zip
    asserts("active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).first) }.size 1
    asserts(:add_archive, :zip).raises(Releasy::ConfigError, /already have archive format :zip/i)
    asserts(:add_archive, :unknown).raises(ArgumentError, /unsupported archive/i)

    context "#verbose" do
      hookup { topic.quiet }
      hookup { topic.verbose }
      asserts(:verbose?).equals true
    end

    context "#quiet" do
      hookup { topic.verbose }
      hookup { topic.quiet }
      asserts(:verbose?).equals false
    end

    context "#create_md5s" do
      hookup { topic.create_md5s }
      asserts(:create_md5s?).equals true
    end

    context "#files" do
      hookup { topic.files = ["fish.rb"] }
      asserts(:files).size 1
      asserts(:files).kind_of Rake::FileList
    end

    context "#exposed_files" do
      hookup { topic.exposed_files = "fish.rb" }
      asserts(:exposed_files).size 1
      asserts(:exposed_files).kind_of Rake::FileList
    end
  end

  context "defined" do
    setup do
      Releasy::Project.new do
        name "Test Project - (2a)"
        version "v0.1.5"

        add_archive :"7z"
        add_archive :zip

        add_build :source
        add_build :osx_app do
          add_archive :tar_gz do
            extension ".tgz"
          end
          wrapper Dir["../wrappers/gosu-mac-wrapper-*.tar.gz"].first
          url "org.url.app"
        end
        add_build :windows_standalone do
          exclude_encoding
        end

        files source_files

        add_link "www.frog.com", "Frog"
        add_link "www2.fish.com", "Fish"
      end
    end

    asserts(:to_s).equals %[<Releasy::Project Test Project - (2a) v0.1.5>]
    asserts(:name).equals "Test Project - (2a)"
    asserts(:underscored_name).equals "test_project_2a"
    asserts(:version).equals "v0.1.5"
    asserts("file") { topic.files.to_a }.same_elements source_files
    asserts(:underscored_version).equals "v0_1_5"
    asserts(:description).equals "Test Project - (2a) v0.1.5"
    asserts(:underscored_description).equals "test_project_2a_v0_1_5"
    asserts(:executable).equals "bin/test_project_2a"
    asserts(:folder_base).equals "pkg/test_project_2a_v0_1_5"
    asserts(:links).equals "www.frog.com" => "Frog", "www2.fish.com" => "Fish"

    asserts(:active_builders).size(Gem.win_platform? ? 3 : 2)
    asserts("source active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :source }) }.size 2
    asserts("osx app active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :osx_app }) }.size 3
    if Gem.win_platform?
      asserts("Windows standalone active_archivers") { topic.send(:active_archivers, topic.send(:active_builders).find {|b| b.type == :windows_standalone }) }.size 2
    end

    asserts "add_build yields an instance_eval-ed Releasy::DSLWrapper" do
      correct = false
      topic.add_build :windows_folder do
        correct = (is_a?(Releasy::DSLWrapper) and owner.is_a?(Releasy::Builders::WindowsFolder))
      end
      correct
    end

    asserts "add_archive yields an instance_eval-ed Releasy::DSLWrapper" do
      correct = false
      topic.add_archive :tar_gz do
        correct = (is_a?(Releasy::DSLWrapper) and owner.is_a?(Releasy::Archivers::TarGzip))
      end
      correct
    end

    context "#generate_archive_tasks" do
      asserts(:generate_archive_tasks).equals { topic }

      should "call generate_tasks on all archivers" do
        topic.send(:active_builders).each do |builder|
          topic.send(:active_archivers, builder).each {|a| mock(a).generate_tasks(builder.type.to_s.sub('_', ':'), builder.send(:folder), []) }
        end
        topic.send :generate_archive_tasks
      end
    end

    context "#generate_tasks" do
      asserts(:generate_tasks).equals { topic }

      should "call generate_tasks on all builders" do
        topic.send(:active_builders) {|b| mock(b).generate_tasks }
        topic.send :generate_tasks
      end

      should "call #generate_archive_tasks" do
        mock(topic).generate_archive_tasks
        topic.send :generate_tasks
      end
    end

    context "defined with Object#tap-like syntax" do
      setup do
        Releasy::Project.new do |p|
          p.name = "Test Project - (2a)"
          p.version = "v0.1.5"

          p.add_archive :"7z"
          p.add_archive :zip

          p.add_build :source
          p.add_build :osx_app do |b|
            b.add_archive :tar_gz do |a|
              a.extension = ".tgz"
            end
            b.wrapper = Dir["../wrappers/gosu-mac-wrapper-*.tar.gz"].first
            b.url = "org.url.app"
          end
          p.add_build :windows_standalone do |b|
            b.exclude_encoding
          end

          p.files = source_files

          p.add_link "www.frog.com", "Frog"
          p.add_link "www2.fish.com", "Fish"
        end
      end

      # Just needed to test that the project was passing into the block.
      asserts(:name).equals "Test Project - (2a)"
    end
  end
end