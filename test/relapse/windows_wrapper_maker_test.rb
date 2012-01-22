require File.expand_path("../teststrap", File.dirname(__FILE__))

if Gem.win_platform?
  require File.expand_path("../../lib/relapse/windows_wrapper_maker", File.dirname(__FILE__))

  folder = windows_folder_wrapper

  context Relapse::WindowsWrapperMaker do
    setup { Relapse::WindowsWrapperMaker.new }

    context '#build_executable' do
      hookup do
        # Can't mock on Ocra::OcraBuilder unless it has been loaded already.
        topic.send(:load_ocra) unless defined? Ocra::OcraBuilder
      end

      helper :mock_ocra do |exe, script, ruby_exe, windows, options|
        builder = Object.new
        mock(builder).setenv("RUBYOPT", options[:rubyopt] || '')
        mock(builder).setenv("RUBYLIB", options[:rubylib] || '')
        mock(builder).setenv("GEM_PATH", "\xFF\\#{options[:gem_path] || "gemhome"}")
        mock(builder).postcreateprocess(Ocra::Pathname("\xFF\\bin\\#{ruby_exe}"), "#{ruby_exe} \"\xFF\\#{script}\"")

        mock(Ocra::OcraBuilder).new(exe, windows).yields(builder)
      end

      helper :check_options do |icon|
        options = Ocra.instance_variable_get(:@options)
        options[:lzma_mode] == false and
            options[:chdir_first] == true and
            options[:icon_filename] == icon
      end

      should "make a windows exe" do
        mock_ocra 's.exe', 's.rb', 'rubyw.exe', true, {}
        topic.build_executable "s.exe", "s.rb", :windows => true
        check_options nil
      end

      should "make a console exe" do
        mock_ocra 's.exe', 's.rb', 'ruby.exe', false, {}
        topic.build_executable "s.exe", "s.rb"
        check_options nil
      end

      should "add an icon" do
        mock_ocra 's.exe', 's.rb', 'ruby.exe', false, {}
        topic.build_executable "s.exe", "s.rb", :icon => "icon.ico"
        check_options "icon.ico"
      end

      should "set up correct environment" do
        mock_ocra 's.exe', 's.rb', 'ruby.exe', false, :rubyopt => "x", :rubylib => "y", :gem_path => "z"
        topic.build_executable "s.exe", "s.rb", :rubyopt => "x", :rubylib => "y", :gem_path => "z"
        check_options nil
      end
    end

    context '#build_wrapper' do
      hookup do
        FileUtils.rm_r folder if File.directory? folder
        topic.build_wrapper folder, %w[ray], "test_project/test_app.ico"
      end

      %w[windows.exe console.exe relapse_runner.rb bin/ruby.exe bin/rubyw.exe].each do |file|
        asserts("#{file} present") { File.exists? "#{folder}/#{file}" }
      end

      asserts("plenty of dlls copied") { Dir["#{folder}/bin/*.dll"].size >= 6 }

      %w[ray].each do |gem|
        asserts("#{gem} gem specification copied") { not Dir["#{folder}/gemhome/specifications/#{gem}*.gemspec"].empty? }
        asserts("#{gem} gem folder copied") { not Dir["#{folder}/gemhome/gems/#{gem}*"].empty? }
      end

      asserts("console output") { %x[#{folder}/console.exe] }.equals "Relapse runner has run!\n"
      asserts("windows output") { %x[#{folder}/windows.exe] }.equals "Relapse runner has run!\n"
    end
  end
end