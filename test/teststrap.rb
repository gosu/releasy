require 'rubygems'
require 'bundler/setup'
require 'riot'
require 'riot/rr'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'releasy'

if ARGV.include? "--verbose" or ARGV.include? "-v"
  Riot.verbose
else
  Riot.pretty_dots
end

def source_files
  %w[bin/test_app lib/test_app.rb lib/test_app/stuff.rb README.txt LICENSE.txt Gemfile.lock Gemfile]
end

def project_path
  File.expand_path("../../test_project", __FILE__)
end

def test_tasks(tasks)
  tasks.each do |type, name, prerequisites|
    asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
    asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.same_elements prerequisites
  end

  asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
end

def active_builders_valid
  asserts("#active_builders are valid") { topic.send(:active_builders).all?(&:valid_for_platform?) }
end

def osx_platform?; !!(RUBY_PLATFORM =~ /darwin/); end

def windows_folder_wrapper; "windows_wrapper/ruby_#{RUBY_VERSION.tr(".", "_")}p#{RUBY_PATCHLEVEL}_win32_wrapper"; end

def same_contents?(file1, file2)
  File.readlines(file1).map(&:strip) == File.readlines(file2).map(&:strip)
end
$original_path = Dir.pwd

def output_path; "../test_output"; end

Releasy::Mixins::Log.log_level = :silent

# Ensure that the output directory is clean before starting tests, but don't do it for every test.
output_dir = "test_output"
if File.directory? output_dir
  puts "Deleting existing test outputs"
  rm_r FileList["#{output_dir}/*"], :verbose => false
else
  mkdir output_dir, :verbose => false
end



