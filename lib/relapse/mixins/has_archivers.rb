module Relapse
module Mixins
  module HasArchivers
    def initialize
      @archivers = []
    end

    # Add an archive type to be generated for each of your outputs.
    #
    # @param type [:exe, :"7z", :tar_bz2, :tar_gz, :zip]
    # @return [Project] self
    def add_archive(type, &block)
      raise ArgumentError, "Unsupported archive format #{type.inspect}" unless Archivers.has_type? type
      raise ConfigError, "Already have archive format #{type.inspect}" if @archivers.any? {|a| a.type == type }

      archiver = Archivers[type].new(respond_to?(:project) ? project : self)
      @archivers << archiver

      Dsl.new(archiver).instance_eval(&block) if block_given?

      archiver
    end

    protected
    # @return [Array<Archiver>]
    def active_archivers
      @archivers
    end
  end
end
end