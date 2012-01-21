require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::WindowsBuilder do
  setup do
    # Constant required to allow object to be created, since class is abstact.
    Relapse::Builders::WindowsBuilder.send(:const_set, :DEFAULT_FOLDER_SUFFIX, '')
    Relapse::Builders::WindowsBuilder.new new_project
  end

  teardown do
    Relapse::Builders::WindowsBuilder.send(:remove_const, :DEFAULT_FOLDER_SUFFIX)
  end

  context "undefined executable_type" do
    setup do
      project = new_project
      project.executable = "frog"

      Relapse::Builders::WindowsBuilder.new project
    end

    asserts(:ocra_command).raises Relapse::ConfigError, "Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console"
  end
end