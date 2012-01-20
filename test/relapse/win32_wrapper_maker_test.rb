require File.expand_path("../teststrap", File.dirname(__FILE__))

if Gem.win_platform?
  require File.expand_path("../../lib/relapse/win32_wrapper_maker", File.dirname(__FILE__))

  context Relapse::Win32WrapperMaker do
    folder = win32_folder_wrapper

    context '.build_wrapper' do
      hookup do
        FileUtils.rm_r folder if File.directory? folder
        Relapse::Win32WrapperMaker.build_wrapper folder, %w[ray], "test_project/test_app.ico"
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