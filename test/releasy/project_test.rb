require File.expand_path("../teststrap", File.dirname(__FILE__))

# Change directory into the project, since that is where we work from normally.

folder_base = "pkg/test_project_2a_v0_1_5"

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
    asserts(:links).equals Hash.new
    asserts(:create_md5s?).equals false
    asserts(:encoding_excluded?).equals false

    asserts(:to_s).equals "<Releasy::Project>"
    asserts(:output_path).equals "pkg"
    asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

    asserts("attempting to generate tasks without any outputs") { topic.send :generate_tasks }.raises Releasy::ConfigError, /Must use #add_build at least once before tasks can be generated/i

    asserts(:active_builders).empty
    asserts(:add_build, :source).kind_of Releasy::Builders::Source
    asserts(:active_builders).size 1
    asserts(:add_build, :source).raises(ArgumentError, /already have output :source/i)
    asserts(:add_build, :unknown).raises(ArgumentError, /unsupported output/i)

    asserts("active_packagers") { topic.send(:active_packagers, topic.send(:active_builders).first) }.empty
    asserts(:add_package, :zip).kind_of Releasy::Packagers::Zip
    asserts("active_packagers") { topic.send(:active_packagers, topic.send(:active_builders).first) }.size 1
    asserts(:add_package, :zip).raises(ArgumentError, /already have archive format :zip/i)
    asserts(:add_package, :unknown).raises(ArgumentError, /unsupported archive/i)

    context "#verbose" do
      hookup { topic.verbose }
      asserts(:log_level).equals :verbose
    end

    context "#silent" do
      hookup { topic.silent }
      asserts(:log_level).equals :silent
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
    helper(:pretend_windows) { stub(Releasy).win_platform?.returns true }
    helper(:pretend_not_windows) { stub(Releasy).win_platform?.returns false }

    setup do
      Releasy::Project.new do
        name "Test Project - (2a)"
        version "v0.1.5"

        add_package :"7z"
        add_package :zip
        exclude_encoding

        add_build :source
        
        add_build :osx_app do
          wrapper "../wrappers/gosu-mac-wrapper-0.7.41.tar.gz"
          url "org.url.app"
        end

        add_build :windows_installer

        files source_files

        add_link "www.frog.com", "Frog"
        add_link "www2.fish.com", "Fish"
        
        add_deploy :local
      end
    end

    asserts(:encoding_excluded?).equals true
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

    asserts(:active_builders) do
      pretend_windows
      topic.send :active_builders
    end.size 3

    asserts(:active_builders) do
      pretend_not_windows
      topic.send :active_builders
    end.size 2

    asserts("source active_packagers") { topic.send(:active_packagers, topic.send(:active_builders).find {|b| b.type == :source }) }.size 2
    asserts("osx app active_packagers") { topic.send(:active_packagers, topic.send(:active_builders).find {|b| b.type == :osx_app }) }.size 2
    asserts("Windows standalone active_packagers") do
      pretend_windows
      topic.send(:active_packagers, topic.send(:active_builders).find {|b| b.type == :windows_installer })
    end.size 2

    context "adding builds and packages" do
      asserts "#add_build yields an instance_eval-ed Releasy::DSLWrapper" do
        correct = false
        topic.add_build :windows_standalone do
          correct = (is_a?(Releasy::DSLWrapper) and owner.is_a?(Releasy::Builders::WindowsStandalone))
        end
        correct
      end

      asserts "#add_package yields an instance_eval-ed Releasy::DSLWrapper" do
        correct = false
        topic.add_package :tar_gz do
          correct = (is_a?(Releasy::DSLWrapper) and owner.is_a?(Releasy::Packagers::TarGzip))
        end
        correct
      end
    end

    context "#generate_archive_tasks" do
      asserts(:generate_archive_tasks).equals { topic }

      should "call #generate_tasks on all packagers" do
        topic.send(:active_builders).each do |builder|
          topic.send(:active_packagers, builder).each do |packager|
            mock(packager).generate_tasks(builder.type.to_s.sub('_', ':'), builder.send(:folder), satisfy {|a| a.size == 1 and a.first.is_a? Releasy::Deployers::Local })
          end
        end
        topic.send :generate_archive_tasks
      end
    end

    context "#generate_deploy_tasks" do
      context "without namespace" do
        setup do
          Rake::Task.clear
          topic.send :generate_deploy_tasks, %w[a b]
        end

        tasks = [
            [ :Task, "deploy", %w[deploy:a deploy:b] ],
            [ :Task, "deploy:local", %w[deploy:a:local deploy:b:local] ],
            [ :Task, "deploy:a", %w[deploy:a:local] ],
            [ :Task, "deploy:b", %w[deploy:b:local] ],
        ]

        test_tasks tasks
      end

      context "with namespace" do
        setup do
          Rake::Task.clear
          topic.send :generate_deploy_tasks, %w[c:a c:b]
        end

        tasks = [
            [ :Task, "deploy:c:local", %w[deploy:c:a:local deploy:c:b:local] ],
            [ :Task, "deploy:c:a", %w[deploy:c:a:local] ],
            [ :Task, "deploy:c:b", %w[deploy:c:b:local] ],
        ]

        test_tasks tasks
      end
    end

    context "#generate_tasks" do
      asserts(:generate_tasks).equals { topic }

      should "call #generate_tasks on all builders" do
        topic.send(:active_builders) {|b| mock(b).generate_tasks }
        topic.send :generate_tasks
      end

      should "call #generate_archive_tasks" do
        mock(topic).generate_archive_tasks
        topic.send :generate_tasks
      end

      context "generated tasks" do
        hookup do
          pretend_windows
          topic.send :generate_tasks
        end

        tasks = [
            [ :Task, "deploy", %w[deploy:source deploy:osx deploy:windows] ],
            [ :Task, "deploy:local", %w[deploy:source:local deploy:osx:local deploy:windows:local] ],
            [ :Task, "deploy:source", %w[deploy:source:local] ],
            
            [ :Task, "deploy:source:local", %w[deploy:source:zip:local deploy:source:7z:local] ],
            [ :Task, "deploy:source:zip", %w[deploy:source:zip:local] ],
            [ :Task, "deploy:source:zip:local", %w[package:source:zip] ],
            [ :Task, "deploy:source:7z", %w[deploy:source:7z:local] ],
            [ :Task, "deploy:source:7z:local", %w[package:source:7z] ],

            [ :Task, "deploy:osx", %w[deploy:osx:local] ],
            [ :Task, "deploy:osx:app", %w[deploy:osx:app:local] ],
            [ :Task, "deploy:osx:local", %w[deploy:osx:app:local] ],
            [ :Task, "deploy:osx:app:local", %w[deploy:osx:app:zip:local deploy:osx:app:7z:local] ],
            [ :Task, "deploy:osx:app:zip", %w[deploy:osx:app:zip:local] ],
            [ :Task, "deploy:osx:app:zip:local", %w[package:osx:app:zip] ],
            [ :Task, "deploy:osx:app:7z", %w[deploy:osx:app:7z:local] ],
            [ :Task, "deploy:osx:app:7z:local", %w[package:osx:app:7z] ],

            [ :Task, "deploy:windows", %w[deploy:windows:local] ],
            [ :Task, "deploy:windows:installer", %w[deploy:windows:installer:local] ],
            [ :Task, "deploy:windows:local", %w[deploy:windows:installer:local] ],
            [ :Task, "deploy:windows:installer:local", %w[deploy:windows:installer:zip:local deploy:windows:installer:7z:local] ],
            [ :Task, "deploy:windows:installer:zip", %w[deploy:windows:installer:zip:local] ],
            [ :Task, "deploy:windows:installer:zip:local", %w[package:windows:installer:zip] ],
            [ :Task, "deploy:windows:installer:7z", %w[deploy:windows:installer:7z:local] ],
            [ :Task, "deploy:windows:installer:7z:local", %w[package:windows:installer:7z] ],

            [ :Task, "package", %w[package:source package:osx package:windows] ],
                
            [ :Task, "package:source", %w[package:source:7z package:source:zip] ],
            [ :Task, "package:source:zip", ["#{folder_base}_SOURCE.zip"] ],
            [ :Task, "package:source:7z", ["#{folder_base}_SOURCE.7z"] ],

            [ :Task, "package:osx", %w[package:osx:app] ],
            [ :Task, "package:osx:app", %w[package:osx:app:7z package:osx:app:zip] ],
            [ :Task, "package:osx:app:zip", ["#{folder_base}_OSX.zip"] ],
            [ :Task, "package:osx:app:7z", ["#{folder_base}_OSX.7z"] ],

            [ :Task, "package:windows", %w[package:windows:installer] ],
            [ :Task, "package:windows:installer", %w[package:windows:installer:7z package:windows:installer:zip] ],
            [ :Task, "package:windows:installer:zip", ["#{folder_base}_WIN32_INSTALLER.zip"] ],
            [ :Task, "package:windows:installer:7z", ["#{folder_base}_WIN32_INSTALLER.7z"] ],

            [ :Task, "build", %w[build:source build:osx build:windows] ],
            [ :Task, "build:source", ["#{folder_base}_SOURCE"] ],
            [ :Task, "build:osx", %w[build:osx:app] ],
            [ :Task, "build:osx:app", ["#{folder_base}_OSX"] ],
            [ :Task, "build:windows", %w[build:windows:installer] ],
            [ :Task, "build:windows:installer", ["#{folder_base}_WIN32_INSTALLER"] ],

            # [ :FileTask, 'pkg', [] ],

            [ :FileTask, "#{folder_base}_SOURCE", source_files ],
            [ :FileTask, "#{folder_base}_SOURCE.7z", ["#{folder_base}_SOURCE"] ],
            [ :FileTask, "#{folder_base}_SOURCE.zip", ["#{folder_base}_SOURCE"] ],

            [ :FileTask, "#{folder_base}_OSX", source_files + ["../wrappers/gosu-mac-wrapper-0.7.41.tar.gz"] ],
            [ :FileTask, "#{folder_base}_OSX.7z", ["#{folder_base}_OSX" ] ],
            [ :FileTask, "#{folder_base}_OSX.zip", ["#{folder_base}_OSX"] ],

            [ :FileTask, "#{folder_base}_WIN32_INSTALLER", source_files ],
            [ :FileTask, "#{folder_base}_WIN32_INSTALLER.7z", ["#{folder_base}_WIN32_INSTALLER"] ],
            [ :FileTask, "#{folder_base}_WIN32_INSTALLER.zip", ["#{folder_base}_WIN32_INSTALLER"] ],
        ]

        test_tasks tasks
      end
    end

    context "defined with Object#tap-like syntax" do
      setup do
        Releasy::Project.new do |p|
          p.name = "Test Project - (2a)"
          p.version = "v0.1.5"

          p.add_package :"7z"
          p.add_package :zip

          p.add_build :source
          p.add_build :osx_app do |b|
            b.add_package :tar_gz do |a|
              a.extension = ".tgz"
            end
            b.wrapper = "../wrappers/gosu-mac-wrapper-0.7.41.tar.gz"
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