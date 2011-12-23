require File.expand_path("helper", File.dirname(__FILE__))

module ReleasePackager
  context Project do

    context "Default" do
      setup { Project.new(:test_project) }

      asserts(:id).equals :test_project

      # Defaults.
      asserts(:output_path).equals "pkg"

      # Derived values.
      asserts(:name).equals "Test Project"
      asserts(:folder_base).equals "pkg/test_project"

      asserts("Attempting to generate tasks without any outputs") { topic.generate_tasks }.raises(RuntimeError)

      asserts(:add_compression, :zip).equals :zip
      asserts(:add_compression, :unknown).raises(ArgumentError, /unsupported compression/i)

      asserts(:add_output, :source).equals :source
      asserts(:add_output, :unknown).raises(ArgumentError, /unsupported output/i)
    end

    context "Described" do
      setup do
        Project.new(:test_project) do |p|
          p.name = "Test"
          p.version = "v0.1.5"
          p.output_path = "test/pkg"

          p.add_compression :"7z"
          p.add_compression :zip

          p.add_output :source
          p.add_output :win32_standalone

          p.files = ["frog.rb", "fish/frog.rb"]
        end
      end

      asserts(:name).equals "Test"
      asserts(:folder_base).equals "test/pkg/test_project_v0_1_5"
    end
  end
end