require 'rubygems'
require 'bundler'
require 'rake/testtask'
require 'rake/clean'
require 'yard'


CLEAN << "test/test_project/pkg" # Created by running tests.

Bundler::GemHelper.install_tasks

desc "Run all tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = "test/**/*_test.rb"
    t.verbose = false
  end
end

YARD::Rake::YardocTask.new

task :default => :test

desc "Create win32 stubs"
task :stubs do
  load `where ocra`.split("\n").find {|f| File.extname(f) == '' }

  Ocra.find_stubs
  options = Ocra.instance_variable_get(:@options)
  options[:lzma_mode] = false
  options[:chdir_first] = true
  options[:icon_filename] = "test_project/test_app.ico"

  [
      ["stubs/console.exe", false, "ruby.exe"],
      ["stubs/windowed.exe", true, "rubyw.exe"]
  ].each do |path, windowed, ruby_exe|
    Ocra::OcraBuilder.new(path, windowed) do |sb|
      sb.setenv('RUBYOPT', '$RUBYOPT$')
      sb.setenv('RUBYLIB', '$RUBYLIB$')
      sb.setenv('GEM_PATH', Ocra.Pathname(Ocra::GEMHOMEDIR).to_native)

      # Add the opcode to launch the script
      sb.postcreateprocess(Ocra.Pathname("bin\\#{ruby_exe}"), "#{ruby_exe} \"relapse_runner.rb\"")
    end
  end
end
