namespace :win32_wrapper do
  load Gem.bin_path('ocra', 'ocra', Bundler.definition.specs_for([:default]).find {|g| g.name == "ocra" }.version)

  # Need to disable this method so we get the right output.
  Ocra::OcraBuilder.class_eval do
    def createinstdir(*args); end
  end

  options = Ocra.instance_variable_get(:@options)
  options[:lzma_mode] = false
  options[:chdir_first] = true
  options[:icon_filename] = "test_project/test_app.ico"

  output_dir = "win32_wrapper"
  wrapper_name = "ruby_win32_wrapper"
  wrapper_dir = File.join(output_dir, wrapper_name)
  bin_dir = "#{wrapper_dir}/bin"
  gems_dir = "#{wrapper_dir}/gemhome/gems"
  specs_dir = "#{wrapper_dir}/gemhome/specifications"
  runner_file = "#{wrapper_dir}/relapse_runner.rb"

  task :read_ocra_stubs do
    Ocra.find_stubs
  end

  directory output_dir

  desc "Create win32 wrapper"
  task :build => [wrapper_dir, runner_file, 'win32_wrapper:executables']

  file wrapper_dir do
    File.open("#{wrapper_dir}.rb", "w") {|f| f.puts "# nothing" }

    Dir.chdir output_dir do
      ENV['BUNDLE_GEMFILE'] = File.expand_path("../Gemfile", __FILE__)
      command = %[bundle exec ocra #{wrapper_name}.rb --debug-extract --no-dep-run --add-all-core]
      puts command
      system command
    end

    rm "#{wrapper_dir}.rb"

    # Extract the files from the executable.
    system "#{wrapper_dir}.exe"
    rm "#{wrapper_dir}.exe"

    mv Dir["#{output_dir}/ocr*\.tmp"].first, wrapper_dir
    rm "#{wrapper_dir}/src/#{wrapper_name}.rb"

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
  end

  # Redirection file. Is replaced by automated build.
  file runner_file => wrapper_dir do
    File.open(runner_file, "w") do |file|
      file.puts <<END
# Replace this 'puts' command with something like this (you must put your application in the 'src' directory):
# require 'lib/application.rb'
puts "Relapse runner has run!"
END
    end
  end

  stubs = [
      ["#{wrapper_dir}/console.exe", false, Ocra::Host.ruby_exe],
      ["#{wrapper_dir}/windows.exe", true, Ocra::Host.rubyw_exe],
  ]

  task :executables => stubs.map {|d| d.first }

  stubs.each do |executable, windowed, ruby_exe|
    file executable => ['win32_wrapper:read_ocra_stubs', wrapper_dir] do
      Ocra::OcraBuilder.new(executable, windowed) do |sb|
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
