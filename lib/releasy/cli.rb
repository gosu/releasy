require 'cri'

Releasy::Cli = Cri::Command.new_basic_root.modify do
  name        'releasy'
  usage       'releasy [options] [command] [options]'
  summary     'helper for using the Releasy gem'
  description 'Helper for using the Releasy gem to release packages'
end

Dir[File.expand_path("../cli/*.rb", __FILE__)].each do |file|
  require file.chomp(File.extname(file))
end