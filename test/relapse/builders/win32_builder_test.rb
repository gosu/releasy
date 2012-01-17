require File.expand_path("../../teststrap", File.dirname(__FILE__))
require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Win32Builder do
  setup { Relapse::Win32Builder.new new_project }

  context "undefined executable_type" do
    setup do
      project = new_project
      project.executable = "frog"
      Relapse::Win32Builder.new project
    end

    asserts(:ocra_command).raises Relapse::ConfigError, "Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console"
  end
end