# Required only so we know the gem is being copied properly.
require 'rubygems'
require 'bundler/setup' unless defined? OSX_EXECUTABLE_FOLDER # Can't require bundler because the current OSX wrapper is broken.
require 'cri'

require 'test_app/stuff'