require File.expand_path("../teststrap", File.dirname(__FILE__))

include Rake::DSL

if Gem.win_platform?
  folder = 'win32_wrapper/ruby_win32_wrapper'

  context "Rake tasks to build win32 wrapper" do
    hookup do
      rm_r folder if File.directory? folder
      require File.expand_path('../../tasks/win32_wrapper', File.dirname(__FILE__))
    end

    tasks = [
        [:Task, 'win32_wrapper:read_ocra_stubs', []],
        [:Task, 'win32_wrapper:build', [folder, "#{folder}/relapse_runner.rb", 'win32_wrapper:executables']],
        [:Task, 'win32_wrapper:executables', ["#{folder}/console.exe", "#{folder}/windows.exe"]],

        [:FileCreationTask, 'win32_wrapper', []],
        [:FileTask, folder, []],
        [:FileTask, "#{folder}/relapse_runner.rb", [folder]],
        [:FileTask, "#{folder}/console.exe", ['win32_wrapper:read_ocra_stubs', folder]],
        [:FileTask, "#{folder}/windows.exe", ['win32_wrapper:read_ocra_stubs', folder]],
    ]

    test_tasks tasks

    context "build" do
      hookup { Rake::Task['win32_wrapper:build'].invoke }
      teardown { Rake::Task.clear }

      %w[windows.exe console.exe relapse_runner.rb bin/ruby.exe bin/rubyw.exe].each do |file|
        asserts("#{file} present") { File.exists? "#{folder}/#{file}" }
      end

      asserts("plenty of dlls copied") { Dir["#{folder}/bin/*.dll"].size >= 6 }

      %w[chipmunk gosu ray texplay].each do |gem|
        asserts("#{gem} gem specification copied") { not Dir["#{folder}/gemhome/specifications/#{gem}*.gemspec"].empty? }
        asserts("#{gem} gem folder copied") { not Dir["#{folder}/gemhome/gems/#{gem}*"].empty? }
      end

      asserts("console output") { %x[#{folder}/console.exe] }.equals "Relapse runner has run!\n"
      asserts("windows output") { %x[#{folder}/windows.exe] }.equals "Relapse runner has run!\n"
    end
  end
end