require 'fileutils'
require 'ocra'

module Relapse
  # Creates wrappers and executables by wrapping Ocra's functionality.
  class WindowsWrapperMaker
    include FileUtils
    include FileUtils::Verbose

    # Creates an win32 executable file (xxx.exe) that runs via a Ruby executable at bin/ruby(w).exe
    # Paths given to the executable are relative to the directory that the executable is in.
    # Assumes that user's source will be put into _./src/_ and that ruby executables will be in _./bin/_
    #
    # @param executable_file [String] File to create, which should be a .exe file.
    # @param ruby_file [String] Path of script to run with the executable.
    # @option options :rubyopt [String] RUBYOPT environment variable - Options to pass to Ruby ('')
    # @option options :rubylib [String] RUBYLIB environment variable - Paths, relative to _./src/_, to add to $LOAD_PATH ('').
    # @option options :gem_path [String] GEM_PATH environment variable - Path, relative to  _./_, to load gems from ('vendor').
    # @option options :windows [Boolean] True for an application that uses windows, false for a console application (false)
    # @option options :icon [String] Path to Windows icon file (.ico) that the executable should use (nil).
    def build_executable(executable_file, ruby_file, options = {})
      options = {
          :rubyopt => '',
          :rubylib => '',
          :gem_path => 'vendor',
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
        sb.setenv('BUNDLE_GEMFILE', '')
        sb.setenv('BUNDLE_BIN_PATH', '')

        ruby_executable = options[:windows] ? "rubyw.exe" : "ruby.exe"
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

      # If we aren't on Windows, then File::ALT_SEPARATOR won't be defined or will be defined to the local system.
      # To save breaking the world, change it as we load, not in File itself.
      ocra_file = spec.bin_file(spec.executable)
      if Gem.win_platform?
        load ocra_file
      else
        script = File.read(ocra_file)
        # On non-windows, UTF8 is the standard way to load files, which is not what we want at all since it will complain about "\xFF".
        script.force_encoding Encoding::ASCII_8BIT if script.respond_to? :force_encoding
        script.gsub!("File::ALT_SEPARATOR", "'\\\\\\\\'")
        Object.class_eval script, ocra_file
      end

      # Need to disable this method so we get the right output.
      Ocra::OcraBuilder.class_eval do
        def createinstdir(*args); end
      end

      Ocra.find_stubs

      nil
    end
  end
end