require 'rubygems'
require 'bundler'
require 'rake/testtask'
require 'rake/clean'
require 'yard'


CLEAN << "test/test_project/pkg" # Created by running tests.

Bundler::GemHelper.install_tasks

desc "Run all tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = "test/**/*_test.rb"
    t.verbose = false
  end
end

YARD::Rake::YardocTask.new

task :default => :test

# Sadly, Ocra isn't designed to work except on Windows, but we can use the stubs built elsewhere.
if RUBY_PLATFORM =~ /mingw|win32/
  # Load ocra binary, but only once.
  def require_ocra
    return if @ocra_loaded
    @ocra_loaded = true

    load Gem.bin_path('ocra', 'ocra', Bundler.definition.specs_for([:default]).find {|g| g.name == "ocra" }.version)

    Ocra.find_stubs

    # Need to disable this method so we get the right output.
    Ocra::OcraBuilder.class_eval do
      def createinstdir(*args); end
    end
  end

  # TODO: Need to pull in some binary gems, via a bundle?
  # TODO: Rakify all this with dependencies.
  # TODO: Add tests.
  desc "Create win32 wrapper"
  task :win32_wrapper do
    require_ocra

    output_folder = "win32_wrapper"
    wrapper = "ruby_win32_wrapper"
    rm_r output_folder if File.exists? output_folder
    mkdir_p output_folder

    Dir.chdir output_folder do
      bin_dir = "#{wrapper}/bin"
      gems_dir = "#{wrapper}/gemhome/gems"
      specs_dir = "#{wrapper}/gemhome/specifications"

      ENV['BUNDLE_GEMFILE'] = File.expand_path("../test_project/Gemfile", __FILE__)
      File.open("#{wrapper}.rb", "w") {|f| f.puts "# nothing" }
      command = %[bundle exec ocra #{wrapper}.rb --debug-extract --no-dep-run --add-all-core]
      puts command
      system command

      rm "#{wrapper}.rb"

      # Extract the files from the executable.
      system "#{wrapper}.exe"
      rm "#{wrapper}.exe"

      mv Dir["ocr*\.tmp"].first, wrapper
      rm "#{wrapper}/src/#{wrapper}.rb"
      File.open("#{wrapper}/relapse_runner.rb", "w") do |file|
        file.puts <<END
# Replace this 'puts' command with something like this (you must put your application in the 'src' directory):
# require 'lib/application.rb'
puts "Relapse runner has run!"
END
      end

      # Copy rubyw + dlls (ruby is already included for us)
      cp "#{Ocra::Host.bindir}/#{Ocra::Host.rubyw_exe}", bin_dir
      Dir["#{Ocra::Host.bindir}/*.dll"].each do |file|
        cp file, bin_dir unless File.exists? "#{bin_dir}/#{File.basename(file)}"
      end

      # Copy some binary gems.
      mkdir_p gems_dir
      mkdir_p specs_dir

      %w[chipmunk gosu ray texplay].each do |gem|
        gem_rb = %x[gem which #{gem}].strip
        raise if gem_rb.empty?
        gem_dir = File.expand_path("../..", gem_rb)
        cp_r gem_dir, gems_dir
        gem_spec = File.expand_path("../../specifications/#{File.basename gem_dir}.gemspec", gem_dir)
        cp_r gem_spec, specs_dir
      end

      create_stubs(wrapper)
    end
  end

  def create_stubs(folder)
    options = Ocra.instance_variable_get(:@options)
    options[:lzma_mode] = false
    options[:chdir_first] = true
    options[:icon_filename] = "../test_project/test_app.ico"

    [
        ["#{folder}/console.exe", false, Ocra::Host.ruby_exe],
        ["#{folder}/windows.exe", true, Ocra::Host.rubyw_exe],
    ].each do |path, windowed, ruby_exe|
      Ocra::OcraBuilder.new(path, windowed) do |sb|
        sb.setenv('RUBYOPT', '') #'$RUBYOPT$')
        sb.setenv('RUBYLIB', '')
        sb.setenv('GEM_PATH', (Ocra.Pathname(Ocra::TEMPDIR_ROOT) / Ocra::GEMHOMEDIR).to_native)

        exe = Ocra.Pathname(Ocra::TEMPDIR_ROOT) / 'bin' / ruby_exe
        script = (Ocra.Pathname(Ocra::TEMPDIR_ROOT) / 'relapse_runner.rb').to_native

        sb.postcreateprocess(exe, "#{ruby_exe} \"#{script}\"")
      end
    end
  end
end
