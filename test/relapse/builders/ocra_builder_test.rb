require File.expand_path("helpers/helper", File.dirname(__FILE__))

context Relapse::Builders::OcraBuilder do
  setup do
    Class.new(Relapse::Builders::OcraBuilder) do
      const_set :DEFAULT_FOLDER_SUFFIX, ''
    end.new new_project
  end

  hookup do
    topic.send(:setup)
  end

  asserts_topic.kind_of Relapse::Builders::WindowsBuilder
  asserts(:ocra_parameters).equals ""
  asserts(:icon).nil
  asserts("setting incorrect icon") { topic.icon = "frog.png" }.raises ArgumentError, /icon must be a .ico file/
  asserts(:ocra_command).raises Relapse::ConfigError, /Unless the executable file extension is .rbw or .rb, then #executable_type must be explicitly :windows or :console/

  context "#icon=" do
    hookup { topic.icon = "icon.ico" }
    asserts(:icon).equals "icon.ico"
  end

  context "#ocra_command" do
    hookup do
      topic.exclude_encoding
      topic.ocra_parameters = "--wobble"
      topic.project.executable = source_files.first
      topic.executable_type = :console
      topic.icon = "icon.ico"
    end

    helper(:command) { %[ocra "bin/test_app" --console --no-enc --wobble --icon "icon.ico" "lib/test_app.rb" "lib/test_app/stuff.rb" "README.txt" "LICENSE.txt" "Gemfile.lock" "Gemfile"] }
    asserts(:ocra_command).equals { %[bundle exec #{command}] }
  end
end
