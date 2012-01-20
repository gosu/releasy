require "relapse/win32_wrapper_maker"

default_output = "win32_wrapper/ruby_#{RUBY_DESCRIPTION[/[\d\.]+p\d+/].tr(".", "-")}_win32_wrapper"
default_icon = File.expand_path("../../../../test_project/test_app.ico", __FILE__)

Relapse::Cli.define_command do
  name        'win32-wrapper'
  usage       'win32-wrapper [options]'
  aliases
  summary     'build a win32 wrapper (win32 only)'
  description 'Build a win32 wrapper for use to build the :win32_folder_from_wrapper output on non-win32 platforms (runs on win32 only).'

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
      puts "win32-wrapper only available on win32 platform"
      exit 0
    end

    if File.exists? options[:output]
      puts "win32-wrapper: #{options[:output]} already exists"
      exit 0
    end

    Relapse::Win32WrapperMaker.build_wrapper(options[:output], options[:gems].split(/[,;\s]+/), options[:icon])
  end
end

