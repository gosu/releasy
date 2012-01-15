require 'rubygems'
require 'bundler/setup'
require 'riot'
require 'riot/rr'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'relapse'

def source_files
  %w[bin/test_app lib/test_app.rb lib/test_app/stuff.rb README.txt]
end

def project_path
  File.expand_path("../test_project", __FILE__)
end

def test_tasks(tasks)
  tasks.each do |type, name, prerequisites|
    asserts("task #{name}") { Rake::Task[name] }.kind_of Rake.const_get(type)
    asserts("task #{name} prerequisites") { Rake::Task[name].prerequisites }.equals prerequisites
  end

  asserts("no other tasks created") { (Rake::Task.tasks - tasks.map {|d| Rake::Task[d[1]] }).empty? }
end

def test_active_builders
  asserts("#active_builders are valid") { topic.send(:active_builders).all?(&:valid_for_platform?) }
end

def windows?
  RUBY_PLATFORM =~ /mingw|win32/
end

$original_path = Dir.pwd

# Ensure that the pkg directory is clean before starting tests, but don't do it for every test.
if File.directory? "test/test_project/pkg"
  puts "Deleting existing test outputs"
  rm_r FileList["test/test_project/pkg/*"]
end



