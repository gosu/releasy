require File.expand_path("../teststrap", File.dirname(__FILE__))
require File.expand_path("../../lib/relapse/exe_maker", File.dirname(__FILE__))

context Relapse::ExeMaker do
  setup { Relapse::ExeMaker }

  hookup do
    # Can't mock on Ocra::OcraBuilder unless it has been loaded already.
    topic.send(:new).send(:load_ocra) unless defined? Ocra::OcraBuilder
  end

  asserts(".new is private") { topic.private_methods.include? :new }

  context "#create" do
    helper :mock_ocra do |exe, script, ruby_exe, windows, options = {}|
      builder = Object.new
      mock(builder).setenv("RUBYOPT", options[:rubyopt] || '')
      mock(builder).setenv("RUBYLIB", options[:rubylib] || '')
      mock(builder).setenv("GEM_PATH", "\xFF\\#{options[:gem_path] || "gemhome"}")
      mock(builder).postcreateprocess(Ocra::Pathname("\xFF\\bin\\#{ruby_exe}"), "#{ruby_exe} \"\xFF\\#{script}\"")

      mock(Ocra::OcraBuilder).new(exe, windows).yields(builder)
    end

    helper :check_options do |icon = nil|
      options = Ocra.instance_variable_get(:@options)
      options[:lzma_mode] == false and
          options[:chdir_first] == true and
          options[:icon_filename] == icon
    end

    should "make a windows exe" do
      mock_ocra 's.exe', 's.rb', 'rubyw.exe', true
      topic.create "s.exe", "s.rb", :windows => true
      check_options
    end

    should "make a console exe" do
      mock_ocra 's.exe', 's.rb', 'ruby.exe', false
      topic.create "s.exe", "s.rb"
      check_options
    end

    should "adds an icon" do
      mock_ocra 's.exe', 's.rb', 'ruby.exe', false
      topic.create "s.exe", "s.rb", :icon => "icon.ico"
      check_options "icon.ico"
    end

    should "sets up correct environment" do
      mock_ocra 's.exe', 's.rb', 'ruby.exe', false, :rubyopt => "x", :rubylib => "y", :gem_path => "z"
      topic.create "s.exe", "s.rb", :rubyopt => "x", :rubylib => "y", :gem_path => "z"
      check_options
    end
  end
end