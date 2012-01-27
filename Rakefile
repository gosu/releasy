require 'rubygems'
require 'bundler'
Bundler.setup(:development)
require 'rake'
# Hack to ensure rake testtask/clean will load on Ruby 1.8.x
Gem.loaded_specs['rake'].add_self_to_load_path if RUBY_VERSION =~ /^1\.8\.\d+/
require 'rake/testtask'
require 'rake/clean'
require 'yard'

CLEAN << "test_output" # Created by running tests.

Bundler::GemHelper.install_tasks

desc "Run all tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = "test/**/*_test.rb"
    t.verbose = true
  end
end

YARD::Rake::YardocTask.new

desc "Run a yard server to auto-update docs"
task :yard_server do
  system "bundle exec yard server --reload"
end

task :default => :test
