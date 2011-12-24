require File.expand_path("helper", File.dirname(__FILE__))

module ReleasePackager
  context Project do

    context "Default" do
      setup { Project.new }

      # Defaults.
      asserts(:name).nil
      asserts(:underscored_name).nil
      asserts(:ocra_parameters).nil
      asserts(:version).nil
      asserts(:execute).nil
      asserts(:license).nil
      asserts(:icon).nil
      asserts(:installer_group).nil

      asserts(:output_path).equals "pkg"
      asserts(:folder_base).equals "pkg/"

      asserts("Attempting to generate tasks without any outputs") { topic.generate_tasks }.raises(RuntimeError)

      asserts(:add_compression, :zip).equals :zip
      asserts(:add_compression, :unknown).raises(ArgumentError, /unsupported compression/i)

      asserts(:add_output, :source).equals :source
      asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)
    end

    context "Defined" do
      setup do
        Project.new do |p|
          p.name = "Test Project - (2a)"
          p.version = "v0.1.5"
          p.output_path = "test/pkg"

          p.add_compression :"7z"
          p.add_compression :zip

          p.add_output :source
          p.add_output :win32_standalone

          p.files = ["frog.rb", "fish/frog.rb"]
        end
      end

      asserts(:name).equals "Test Project - (2a)"
      asserts(:underscored_name).equals "test_project_2a"
      asserts(:folder_base).equals "test/pkg/test_project_2a_v0_1_5"
    end
  end
end