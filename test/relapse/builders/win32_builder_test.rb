require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::Win32Builder do

  setup do
    # Constant required to allow object to be created, since class is abstact.
    Relapse::Builders::Win32Builder.send(:const_set, :DEFAULT_FOLDER_SUFFIX, '')
    Relapse::Builders::Win32Builder.new new_project
  end

  teardown do
    Relapse::Builders::Win32Builder.send(:remove_const, :DEFAULT_FOLDER_SUFFIX)
  end

  context "undefined executable_type" do
    setup do
      project = new_project
      project.executable = "frog"

      Relapse::Builders::Win32Builder.new project
    end

    asserts(:ocra_command).raises Relapse::ConfigError, "Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console"
  end
end