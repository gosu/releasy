require 'relapse/exe_maker'
require 'fileutils'

module Relapse
  class Win32WrapperMaker
    include FileUtils
    include FileUtils::Verbose

    class << self
      private :new
      def build_wrapper(output_dir, gems, icon)
        new.build_wrapper(output_dir, gems, icon)
      end
    end

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
        ENV['BUNDLE_GEMFILE'] = File.expand_path("../win32_wrapper_maker/Gemfile", __FILE__)
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
      puts "=== Copying pre-compiled binary gems"

      gems.each do |gem|
        puts "Installing #{gem}"
        command = %[gem install #{gem} --install-dir "#{gemhome}"]
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
      Relapse::ExeMaker.create("#{wrapper_dir}/console.exe", ruby_file, :icon => icon)
      Relapse::ExeMaker.create("#{wrapper_dir}/windows.exe", ruby_file, :icon => icon, :windows => true)
    end
  end
end