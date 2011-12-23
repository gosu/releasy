# -*- encoding: utf-8 -*-
require_relative "release_packager/version"

Gem::Specification.new do |s|
  s.name        = "release_packager"
  s.version     = ReleasePackager::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bil Bas (Spooner)"]
  s.email       = ["bil.bagpuss@gmail.com"]
  s.homepage    = "http://github.com/Spooner/release_packager/"
  s.summary     = %q{ReleasePackager helps to make application releases simpler}
  s.description = %q{ReleasePackager helps to make application releases simpler, by outputting source folders, win32 folders, win32 standalone executables, win32 installers}

  s.rubyforge_project = "release_packager"
  s.has_rdoc = true
  s.required_ruby_version = "~> 1.9.2"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('ocra', '~> 1.3.0')
  s.add_development_dependency('riot', '~> 0.12.5')
  s.add_development_dependency('rake')
end
