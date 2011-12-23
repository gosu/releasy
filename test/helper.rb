require 'rubygems'
require 'bundler/setup'
require 'riot'
require 'riot/rr'

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'release_packager'


# TODO: These "rake-mocks" should do more than just print stuff out.

def task(options)
  puts "task #{options.map {|k, v| "#{k} => #{v}"}.join(", ") }"
end

def desc(text)
  puts "\ndesc #{text.inspect}"
end

def file(options)
  puts "file #{options.map {|k, v| "#{k} => #{v}"}.join(", ") }"
end