module Releasy
module Mixins
  # An object that owns one or more instances of {Packagers::Packager}
  module HasPackagers
    # Add an archive type to be generated for each of your outputs.
    # @see Project#initialize
    # @param type [:exe, :"7z", :tar_bz2, :tar_gz, :zip]
    # @return [Project] self
    def add_package(type, &block)
      raise ArgumentError, "Unsupported archive format #{type.inspect}" unless Packagers.has_type? type
      raise ConfigError, "Already have archive format #{type.inspect}" if packagers.any? {|a| a.type == type }

      packager = Packagers[type].new(respond_to?(:project) ? project : self)
      packagers << packager

      if block_given?
        if block.arity == 0
          DSLWrapper.new(packager, &block)
        else
          yield packager
        end
      end

      packager
    end

    protected
    def packagers; @packagers ||= []; end

    protected
    # @return [Array<Packager>]
    def active_packagers
      packagers
    end
  end
end
end