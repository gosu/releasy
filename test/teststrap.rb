require 'rubygems'
require 'bundler/setup'
require 'riot'
require 'riot/rr'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'release_packager'

def source_files
  %w[bin/test lib/test.rb lib/test/stuff.rb README.txt]
end

def project_path
  File.expand_path("../test_project", __FILE__)
end

$original_path = Dir.pwd


