require 'cri'
require "relapse/archivers/exe"

command = 'install-sfx'
sfx_file = Relapse::Archivers::Exe::SFX_NAME
sfx_path = Relapse::Archivers::Exe::SFX_FILE

Relapse::Cli.define_command do
  name        command
  usage       "#{command} [options]"
  aliases
  summary     "copy #{sfx_file} to 7z assets folder"
  description "copy #{sfx_file} to 7z assets folder, after 7z has been installed (required only when not on a Windows system). Warning: This command will likely require 'sudo' to be able to write the file"

  flag   :h, :help,    'show help for this command' do |value, cmd|
    puts cmd.help
    exit 0
  end

  option :t, :output,  "specify directory to copy to (default is to try to find it automatically)", :argument => :required

  run do |options, args, cmd|
    if Gem.win_platform?
      puts "#{command}: only required when not on a Windows platform, since #{sfx_file} is included in the Windows version of 7z"
      exit 0
    end

    exe_location = `which 7z`.strip

    if exe_location.empty?
      puts "#{command}: 7z (p7zip) not installed; install it before trying to use this command"
      exit 0
    end

    assets_location = if options[:output]
                        options[:output]
                      elsif exe_location =~ %r[bin/7z$]
                        exe_location.sub %r[bin/7z$], "lib/p7zip"
                      else
                        nil
                      end

    destination_file = File.join(assets_location, sfx_file)
    if File.exists? destination_file
      puts "#{command}: #{destination_file} already exists; no need to install it again"
      exit 0
    else
      begin
        FileUtils.cp sfx_path, assets_location, verbose: true
        puts "#{sfx_file} copied to #{assets_location}"
      rescue Errno::ENOENT, Errno::EACCES

        if ENV["USER"] != "root"
          command = %[sudo cp "#{sfx_path}" "#{assets_location}"]
          puts "Copy failed, trying again as super-user:\n#{command}"
          exec command
          if File.exists? destination_file
            puts "#{sfx_file} copied to #{assets_location}"
          else
            puts "Failed copy as super-user :("
          end
        end
      end
    end
  end
end