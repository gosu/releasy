# Usage: ruby run_script_for_dependencies.rb <script> <script argument, ...>
# Used internally when needing to build a wrapper when not using Bundler.
# Outputs paths to gemspecs to use which can then be loaded with Gem::Specification.load(spec_path).

# On exit, print out all the gems used.
at_exit do
  if $!.nil? or $!.kind_of?(SystemExit)
    Gem.loaded_specs.each_value do |info|
      puts info.loaded_from
    end

    exit 0
  else
    exit 1
  end
end

# Try to convince it to quit before it runs properly by faking being Ocra.
module Ocra; end
module Releasy; end

# Run the script we are asked to and give it the remaining arguments.
$0 = ARGV[0]
ARGV.shift

# Ensure that the script doesn't think it should use the Releasy gemfile.
ENV['BUNDLE_GEMFILE'], gemfile = '', ENV['BUNDLE_GEMFILE']
load $0
ENV['BUNDLE_GEMFILE'] = gemfile