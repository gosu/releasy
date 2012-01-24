require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::WindowsBuilder do
  setup do
    Class.new(Relapse::Builders::WindowsBuilder) do
      const_set :DEFAULT_FOLDER_SUFFIX, ''
    end
  end

  context "undefined executable_type" do
    setup do
      project = new_project
      project.executable = "frog"

      topic.new project
    end

    asserts(:effective_executable_type).raises Relapse::ConfigError, /Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console/
  end
end