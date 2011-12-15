require 'redcloth'

raise "APP must be defined for release" unless defined? APP
raise "RELEASE_VERSION must be defined for release" unless defined? RELEASE_VERSION

RELEASE_FOLDER = 'pkg'
RELEASE_FOLDER_BASE = File.join(RELEASE_FOLDER, "#{APP}_v#{RELEASE_VERSION.gsub(/\./, '_')}")

README_TEXTILE = "README.textile"
README_HTML = "README.html"
CHANGELOG_FILE = "CHANGELOG.txt"

# Grab all files to include, ignoring raw_media (which just stores work, not finished media).
SOURCE_FOLDER_FILES = `git ls-files`.split("\n").select {|f| f =~ %r[/] and not f =~ /^raw_/ }
SOURCE_FOLDERS = SOURCE_FOLDER_FILES.map {|f| f =~ %r[([^/]+)]; $1 }.uniq

# Files in the base directory that would be nice to include :)
EXTRA_SOURCE_FILES = `git ls-files`.split("\n").grep %r[^[^/]+$]

require_relative "release_packager/win32"
require_relative "release_packager/osx"
require_relative "release_packager/source"

CLOBBER.include(RELEASE_FOLDER, README_HTML)

# Generate a friendly readme
file README_HTML => :readme
desc "Convert readme to HTML"
task readme: README_TEXTILE do
  puts "Converting readme to HTML"
  File.open(README_HTML, "w") do |file|
    file.write RedCloth.new(File.read(README_TEXTILE)).to_html
  end
end

def compress(package, folder, option = '')
  puts "Compressing #{package}"
  rm package if File.exist? package
  cd 'pkg'
  puts File.basename(package)
  puts %x[7z a #{option} "#{File.basename(package)}" "#{File.basename(folder)}"]
  cd '..'
end

desc "Create release packages v#{RELEASE_VERSION} (Not OSX)"
task release: ["release:source", "release:win32:exe", "release:win32:installer"]


# Create archives for release.
{ "7z" => '', :zip => '-tzip' }.each_pair do |compression, option|
  { "source" => RELEASE_FOLDER_SOURCE,
    "win32:exe" => RELEASE_FOLDER_WIN32_EXE,
    "win32:installer" => RELEASE_FOLDER_WIN32_INSTALLER,
  }.each_pair do |name, folder|
    package = "#{folder}.#{compression}"
    desc "Create #{package}"
    task "release:#{name}_#{compression}" => package
    file package => folder do
      compress(package, folder, option)
    end
  end
end