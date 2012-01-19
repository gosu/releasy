require File.expand_path("../../lib/relapse/exe_maker", __FILE__)

namespace :win32_wrapper do
  output_dir = "win32_wrapper"
  wrapper_name = "ruby_win32_wrapper"
  wrapper_dir = File.join(output_dir, wrapper_name)
  bin_dir = "#{wrapper_dir}/bin"
  gems_dir = "#{wrapper_dir}/gemhome/gems"
  specs_dir = "#{wrapper_dir}/gemhome/specifications"
  runner_file = "#{wrapper_dir}/relapse_runner.rb"
  icon = "test_project/test_app.ico"

  directory output_dir

  desc "Create win32 wrapper"
  task :build => [wrapper_dir, runner_file, 'win32_wrapper:executables']

  file wrapper_dir do
    File.open("#{wrapper_dir}.rb", "w") {|f| f.puts "# nothing" }

    Dir.chdir output_dir do
      ENV['BUNDLE_GEMFILE'] = File.expand_path("../Gemfile", __FILE__)
      %x[bundle exec ocra #{wrapper_name}.rb --debug-extract --no-dep-run --add-all-core]
    end

    rm "#{wrapper_dir}.rb"

    # Extract the files from the executable.
    system "#{wrapper_dir}.exe"
    rm "#{wrapper_dir}.exe"

    mv Dir["#{output_dir}/ocr*\.tmp"].first, wrapper_dir
    rm "#{wrapper_dir}/src/#{wrapper_name}.rb"

    # Copy rubyw + dlls (ruby is already included for us)
    rubyw_exe = "#{RbConfig::CONFIG['bindir']}/#{RbConfig::CONFIG['rubyw_install_name'] || "rubyw"}#{RbConfig::CONFIG['EXEEXT'] || ".exe"}"
    cp rubyw_exe, bin_dir
    Dir["#{RbConfig::CONFIG['bindir']}/*.dll"].each do |file|
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

      # Delete superfluous folders.
      %w[examples samples test].each do |dir|
        dir = File.join(gems_dir, File.basename(gem_dir), dir)
        rm_r dir if File.exists? dir and File.directory? dir
      end

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

  task :executables do
    ruby_file = File.basename(runner_file)
    Relapse::ExeMaker.create("#{wrapper_dir}/console.exe", ruby_file, :icon => icon)
    Relapse::ExeMaker.create("#{wrapper_dir}/windows.exe", ruby_file, :icon => icon, :windows => true)
  end
end
