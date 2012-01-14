# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "release_packager/version"

Gem::Specification.new do |s|
  s.name        = "release_packager"
  s.version     = ReleasePackager::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bil Bas (Spooner)"]
  s.email       = ["bil.bagpuss@gmail.com"]
  s.homepage    = "http://spooner.github.com/libraries/release_packager/"
  s.summary     = %q{ReleasePackager helps to make application releases simpler}
  s.description = %q{ReleasePackager helps to make application releases simpler, by outputting source folders, win32 folders, win32 standalone executables, win32 installers}

  s.rubyforge_project = "release_packager"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w[lib]

  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency('ocra', '~> 1.3.0')
    s.add_runtime_dependency('rake')
    s.add_development_dependency('riot', '~> 0.12.5')
    s.add_development_dependency('yard')
  else
    s.add_dependency('ocra', '~> 1.3.0')
    s.add_dependency('rake')
    s.add_dependency('riot', '~> 0.12.5')
    s.add_dependency('yard')
  end
end
