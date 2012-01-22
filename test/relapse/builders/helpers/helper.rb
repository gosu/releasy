require File.expand_path("../../../teststrap", File.dirname(__FILE__))

def new_project
  project = Relapse::Project.new
  project.name = "Test App"
  project.version = "0.1"
  project.files = source_files
  project.exposed_files = %w[README.txt LICENSE.txt]
  project.add_link "http://spooner.github.com/libraries/relapse/", "Relapse website"
  project.verbose = false

  project
end

# Hack to allow test to work using a different gemfile than Relapse's.
def redirect_bundler_gemfile
  bundle_gemfile = ENV['BUNDLE_GEMFILE']
  ENV['BUNDLE_GEMFILE'] = File.expand_path('test_project/Gemfile', $original_path)
  ret_val = yield
  ENV['BUNDLE_GEMFILE'] = bundle_gemfile
  ret_val
end

def data_file(file)
  File.expand_path("test/relapse/builders/data/#{file}", $original_path)
end

def gemspecs_to_use
  # Don't add Relapse since it is may be being run locally and thus not work at all.
  Gem.loaded_specs.values.find_all {|s| %w[bundler cri ocra thor].include? s.name }
end

def link_file
  <<END
[InternetShortcut]
URL=http://spooner.github.com/libraries/relapse/
END
end