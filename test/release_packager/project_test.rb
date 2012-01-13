require File.expand_path("../teststrap", File.dirname(__FILE__))

# Change directory into the project, since that is where we work from normally.

context ReleasePackager::Project do
  teardown do
    Rake::Task.clear
    Dir.chdir $original_path
  end

  hookup do
    Dir.chdir project_path
  end

  context "default" do
    setup { ReleasePackager::Project.new }

    # Defaults are mostly nil.
    asserts(:name).nil
    asserts(:underscored_name).nil
    asserts(:ocra_parameters).nil
    asserts(:version).nil
    asserts(:executable).nil
    asserts(:license).nil
    asserts(:icon).nil
    asserts(:installer_group).nil
    asserts(:files).empty
    asserts(:verbose?).equals true
    asserts(:readme).nil
    asserts(:links).equals Hash.new

    asserts(:output_path).equals "pkg"
    asserts(:folder_base).equals "pkg/" # Would be more, but dependent on name.

    asserts("attempting to generate tasks without any outputs") { topic.generate_tasks }.raises(RuntimeError)

    asserts(:active_archivers).empty
    asserts(:add_archive_format, :zip).equals :zip
    asserts(:active_archivers).equals [ReleasePackager::Archivers::Zip]
    asserts(:add_archive_format, :unknown).raises(ArgumentError, /unsupported archive/i)

    asserts(:active_builders).empty
    asserts(:add_output, :source).equals :source
    asserts(:active_builders).equals [ReleasePackager::Builders::Source]
    asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)
  end

  context "defined" do
    setup do
      ReleasePackager::Project.new do |p|
        p.name = "Test Project - (2a)"
        p.version = "v0.1.5"

        p.add_archive_format :"7z"
        p.add_archive_format :zip

        p.add_output :source
        p.add_output :win32_standalone

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
    asserts(:active_builders).equals [ReleasePackager::Builders::Source, ReleasePackager::Builders::Win32Standalone]
    asserts(:active_archivers).equals [ReleasePackager::Archivers::SevenZip, ReleasePackager::Archivers::Zip]
  end
end