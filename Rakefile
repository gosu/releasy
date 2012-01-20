require 'rubygems'
require 'bundler/setup'
require 'rake/testtask'
require 'rake/clean'
require 'yard'

CLEAN << "test/test_project/pkg" # Created by running tests.
CLOBBER << "win32_wrapper/*" # Created by generating the win32_wrapper.

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
