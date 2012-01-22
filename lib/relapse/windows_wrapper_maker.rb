require 'fileutils'
require 'ocra'

module Relapse
  # Creates wrappers and executables by wrapping Ocra's functionality.
  class WindowsWrapperMaker
    include FileUtils
    include FileUtils::Verbose

    # Builds a win32 compatible wrapper (on a win32 system) that can be used to build applications for win32 when not on a win32 system.
    #
    # @param wrapper_dir [String] Path of wrapper to create.
    # @param gems [Array<String>] List of gems to include (should be binary gems that aren't pre-compiled).
    # @param icon [String] Path of a Windows icon (.ico).
    def build_wrapper(wrapper_dir, gems, icon)
      raise ArgumentError, "'#{wrapper_dir}' already exists" if File.exists? wrapper_dir

      output_dir = File.dirname wrapper_dir
      mkdir_p output_dir unless File.exists? output_dir
      raise ArgumentError, "'#{output_dir}' isn't a directory" unless File.directory? output_dir

      wrapper_name = File.basename wrapper_dir
      runner_file = "#{wrapper_dir}/relapse_runner.rb"

      puts "=== Creating Ocra package from script"
      File.open("#{wrapper_dir}.rb", "w") {|f| f.puts "# nothing" }

      Dir.chdir output_dir do
        ENV['BUNDLE_GEMFILE'] = File.expand_path("../windows_wrapper_maker/Gemfile", __FILE__)
        command = %[bundle exec ocra #{wrapper_name}.rb --debug-extract --no-dep-run --add-all-core]
        output = `#{command}`
        puts output
      end

      rm "#{wrapper_dir}.rb"

      # Extract the files from the executable.
      puts "=== Extracting wrapper from ocra package"
      system "#{wrapper_dir}.exe"
      rm "#{wrapper_dir}.exe"

      mv Dir["#{output_dir}/ocr*\.tmp"].first, wrapper_dir
      rm "#{wrapper_dir}/src/#{wrapper_name}.rb"

      copy_dlls "#{wrapper_dir}/bin"
      install_gems gems, "#{wrapper_dir}/gemhome"
      create_runner_file runner_file
      create_executables wrapper_dir, File.basename(runner_file), icon
    end

    # Creates an win32 executable file (xxx.exe) that runs via a Ruby executable at bin/ruby(w).exe
    # Paths given to the executable are relative to the directory that the executable is in.
    # Assumes that user's source will be put into _./src/_ and that ruby executables will be in _./bin/_
    #
    # @param executable_file [String] File to create, which should be a .exe file.
    # @param ruby_file [String] Path of script to run with the executable.
    # @option options :rubyopt [String] RUBYOPT environment variable - Options to pass to Ruby ('')
    # @option options :rubylib [String] RUBYLIB environment variable - Paths, relative to _./src/_, to add to $LOAD_PATH ('').
    # @option options :gem_path [String] GEM_PATH environment variable - Path, relative to  _./_, to load gems from ('gemhome').
    # @option options :windows [Boolean] True for an application that uses windows, false for a console application (false)
    # @option options :icon [String] Path to Windows icon file (.ico) that the executable should use (nil).
    def build_executable(executable_file, ruby_file, options = {})
      options = {
          :rubyopt => '',
          :rubylib => '',
          :gem_path => 'gemhome',
          :windows => false,
          :icon => nil,
      }.merge! options

      load_ocra unless defined? Ocra::OcraBuilder
      set_ocra_options options[:icon]

      Ocra::OcraBuilder.new(executable_file, options[:windows]) do |sb|
        root = Ocra.Pathname Ocra::TEMPDIR_ROOT

        sb.setenv('RUBYOPT', options[:rubyopt])
        sb.setenv('RUBYLIB', options[:rubylib])
        sb.setenv('GEM_PATH', (root / options[:gem_path]).to_native)

        ruby_executable = options[:windows] ? Ocra::Host.rubyw_exe : Ocra::Host.ruby_exe
        exe = root / 'bin' / ruby_executable
        script = (root / ruby_file).to_native

        sb.postcreateprocess(exe, "#{ruby_executable} \"#{script}\"")
      end

      nil
    end

    protected
    def set_ocra_options(icon)
      options = Ocra.instance_variable_get(:@options)
      options[:lzma_mode] = false
      options[:chdir_first] = true
      options[:icon_filename] = icon

      nil
    end

    protected
    def load_ocra
      Object.send(:remove_const, :Ocra) # remove the "class Ocra", so we can load the "module Ocra"
      spec = Gem.loaded_specs['ocra']
      load spec.bin_file(spec.executable)

      # Need to disable this method so we get the right output.
      Ocra::OcraBuilder.class_eval do
        def createinstdir(*args); end
      end

      Ocra.find_stubs

      nil
    end

    protected
    def copy_dlls(bin_dir)
      puts "=== Copying Ruby dlls"
      # Copy rubyw + dlls (ruby is already included for us)
      rubyw_exe = "#{RbConfig::CONFIG['bindir']}/#{RbConfig::CONFIG['rubyw_install_name'] || "rubyw"}#{RbConfig::CONFIG['EXEEXT'] || ".exe"}"
      cp rubyw_exe, bin_dir
      Dir["#{RbConfig::CONFIG['bindir']}/*.dll"].each do |file|
        cp file, bin_dir unless File.exists? "#{bin_dir}/#{File.basename(file)}"
      end
    end

    protected
    # Copy some binary gems.
    def install_gems(gems, gemhome)
      puts "=== Installing pre-compiled binary gems"

      gems.each do |gem|
        puts "Installing #{gem}"
        command = %[gem install #{gem} --install-dir "#{gemhome}" --no-rdoc --no-ri --ignore-dependencies]
        puts command
        puts %x[#{command}]
      end
    end

    protected
    # Redirection file. Is replaced by automated build.
    def create_runner_file(runner_file)
      puts "=== Creating runner file"
      File.open(runner_file, "w") do |file|
        file.puts <<END
# Replace this 'puts' command with something like this (you must put your application in the 'src' directory):
# require 'lib/application.rb'
puts "Relapse runner has run!"
END
      end
    end

    protected
    def create_executables(wrapper_dir, ruby_file, icon)
      puts "=== Creating executables"
      build_executable("#{wrapper_dir}/console.exe", ruby_file, :icon => icon)
      build_executable("#{wrapper_dir}/windows.exe", ruby_file, :icon => icon, :windows => true)
    end
  end
end