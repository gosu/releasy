require_relative '../lib/release_packager'
require 'riot'
require 'riot/rr'

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