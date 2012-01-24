require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::WindowsBuilder do
  setup do
    Class.new(Relapse::Builders::WindowsBuilder) do
      const_set :DEFAULT_FOLDER_SUFFIX, ''
    end.new new_project
  end

  context "#executable_type undefined and Project#executable doesn't have meaningful extension" do
    hookup { topic.project.executable = "fred" }
    asserts(:effective_executable_type).raises Relapse::ConfigError, /Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console/
  end

  context "valid" do
    hookup { topic.executable_type = :console }

    asserts(:effective_executable_type).equals :console
    asserts(:encoding_excluded?).equals false

    context "exclude_encoding" do
      hookup { topic.exclude_encoding }
      asserts(:encoding_excluded?).equals true
    end
  end
end