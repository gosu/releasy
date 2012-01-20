require 'cri'

Relapse::Cli = Cri::Command.new_basic_root.modify do
  name        'relapse'
  usage       'relapse [options] [command] [options]'
  summary     'helper for using the Relapse gem'
  description 'Helper for using the Relapse gem to release packages'
end

Dir[File.expand_path("../cli/*.rb", __FILE__)].each do |file|
  require file.chomp(File.extname(file))
end