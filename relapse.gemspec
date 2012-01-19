# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "relapse/version"

Gem::Specification.new do |s|
  s.name        = "relapse"
  s.version     = Relapse::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bil Bas (Spooner)"]
  s.email       = ["bil.bagpuss@gmail.com"]
  s.homepage    = "http://spooner.github.com/libraries/relapse/"
  s.summary     = %q{Relapse helps to make Ruby application releases simpler}
  s.description = <<END
#{s.summary}, by creating and archiving source folders, win32 folders,
win32 standalone executables, win32 installers and osx app bundles
END

  s.licenses = ["GNU LGPL"] # Since I include a file from 7z.
  s.rubyforge_project = "relapse"

  s.requirements << '7z (optional; used to generate archives)'
  s.requirements << 'InnoSetup (optional on Windows; used to make Win32 installer)'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = Dir["test/**/*_test.rb"]
  s.require_paths = %w[lib]

  s.add_runtime_dependency('ocra', '~> 1.3.0')
  s.add_runtime_dependency('rake')
  s.add_development_dependency('riot', '~> 0.12.5')
  s.add_development_dependency('rr', '~> 1.0.4')
  s.add_development_dependency('yard')
end
