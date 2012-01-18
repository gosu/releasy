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

    rm_r "win32_wrapper" if File.exists? "win32_wrapper"
    mkdir_p "win32_wrapper"

    Dir.chdir "win32_wrapper" do
      ENV['BUNDLE_GEMFILE'] = File.expand_path("../test_project/Gemfile", __FILE__)
      File.open("win32_wrapper.rb", "w") {|f| f.puts "# nothing" }
      command = %[bundle exec ocra win32_wrapper.rb --no-lzma --debug-extract --no-dep-run --add-all-core]
      puts command
      system command

      rm "win32_wrapper.rb"

      # Extract the files from the executable.
      system "win32_wrapper.exe"
      rm "win32_wrapper.exe"

      mv Dir["ocr*\.tmp"].first, "win32_wrapper"
      rm "win32_wrapper/src/win32_wrapper.rb"
      File.open("win32_wrapper/relapse_runner.rb", "w") do |file|
        file.puts <<END
puts "Relapse runner has run in #{Dir.pwd}"
END
      end

      # Copy rubyw + dlls (ruby is already included for us)
      cp "#{Ocra::Host.bindir}/#{Ocra::Host.rubyw_exe}", "win32_wrapper/bin"
      Dir["#{Ocra::Host.bindir}/*.dll"].each do |file|
        cp file, "win32_wrapper/bin" unless File.exists? "win32_wrapper/bin/#{File.basename(file)}"
      end

      create_stubs
    end
  end

  def create_stubs
    options = Ocra.instance_variable_get(:@options)
    options[:lzma_mode] = false
    options[:chdir_first] = true
    options[:icon_filename] = "../test_project/test_app.ico"

    [
        ["win32_wrapper/console.exe", false, Ocra::Host.ruby_exe],
        ["win32_wrapper/windows.exe", true, Ocra::Host.rubyw_exe],
    ].each do |path, windowed, ruby_exe|
      Ocra::OcraBuilder.new(path, windowed) do |sb|
        sb.setenv('RUBYOPT', '') #'$RUBYOPT$')
        sb.setenv('RUBYLIB', '') #'$RUBYLIB$')
        sb.setenv('GEM_PATH', (Ocra.Pathname(Ocra::TEMPDIR_ROOT) / Ocra::GEMHOMEDIR).to_native)

        exe = Ocra.Pathname(Ocra::TEMPDIR_ROOT) / 'bin' / ruby_exe
        script = (Ocra.Pathname(Ocra::TEMPDIR_ROOT) / 'relapse_runner.rb').to_native

        sb.postcreateprocess(exe, "#{ruby_exe} \"#{script}\"")
      end
    end
  end
end
