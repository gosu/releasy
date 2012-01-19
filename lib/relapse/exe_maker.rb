module Relapse
  class ExeMaker
    class << self
      private :new

      # Creates an win32 executable file (xxx.exe) that runs via a Ruby executable at bin/ruby(w).exe
      # Paths given to the executable are relative to the directory that the executable is in.
      # Assumes that user's source will be put into _./src/_ and that ruby executables will be in _./bin/_

      # @option :rubyopt [String] RUBYOPT environment variable - Options to pass to Ruby ('')
      # @option :rubylib [String] RUBYLIB environment variable - Paths, relative to _./src/_, to add to $LOAD_PATH ('').
      # @option :gem_path [String] GEM_PATH environment variable - Path, relative to  _./_, to load gems from ('gemhome').
      # @option :windows [Boolean] True for an application that uses windows, false for a console application (false)
      # @option :icon [String] Path to Windows icon file (.ico) that the executable should use (nil).
      def create(executable_file, ruby_file, options = {})
        maker = new
        maker.send(:create, executable_file, ruby_file, options)
        maker
      end
    end

    protected
    def create(executable_file, ruby_file, options = {})
      options = {
          rubyopt: '',
          rubylib: '',
          gem_path: 'gemhome',
          windows: false,
          icon: nil,
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
      spec = Gem.loaded_specs['ocra']
      load spec.bin_file(spec.executable)

      # Need to disable this method so we get the right output.
      Ocra::OcraBuilder.class_eval do
        def createinstdir(*args); end
      end

      Ocra.find_stubs

      nil
    end
  end
end