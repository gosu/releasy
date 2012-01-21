require "relapse/windows_wrapper_maker"

default_output = "windows_wrapper/ruby_#{RUBY_DESCRIPTION[/[\d\.]+p\d+/].tr(".", "_")}_win32_wrapper"
default_icon = File.expand_path("../../../../test_project/test_app.ico", __FILE__)

Relapse::Cli.define_command do
  name        'windows-wrapper'
  usage       'windows-wrapper [options]'
  aliases
  summary     'build a Windows wrapper (Windows only)'
  description 'Build a Windows wrapper for use to build the :windows_folder_from_wrapper output on non-Windows platforms (runs on Windows only).'

  flag   :h, :help,    'show help for this command' do |value, cmd|
    puts cmd.help
    exit 0
  end

  #flag   :v, :verbose, ''
  #flag   :q, :quiet, ''
  option :g, :gems,    'list of gems to include', :argument => :required
  option :t, :output,  "specify directory to output to (default is '#{default_output}')", :argument => :required
  option :i, :icon,    "specify icon (.ico file; default is to use the Relapse icon)", :argument => :required

  run do |options, args, cmd|
    options = {
        :output => default_output,
        :gems => '',
        :icon => default_icon,
    }.merge! options

    unless Gem.win_platform?
      puts "windows-wrapper only available on Windows platform"
      exit 0
    end

    if File.exists? options[:output]
      puts "windows-wrapper: #{options[:output]} already exists"
      exit 0
    end

    Relapse::WindowsWrapperMaker.new.build_wrapper(options[:output], options[:gems].split(/[,;\s]+/), options[:icon])
  end
end

