require "releasy/packagers/packager"

module Releasy
module Packagers
  # An packager that tars and then compresses the folder.
  # @abstract
  class TarPackager < Packager
    protected
    def command(folder)
      %[#{seven_zip_command} a -so -mmt -bd -ttar "#{folder}.tar" "#{folder}" | #{seven_zip_command} a -si -bd -t#{self.class::FORMAT} -mx9 "#{folder}#{extension}"]
    end
  end
end
end