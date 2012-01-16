module Relapse
  module HasArchivers
    def initialize
      @archivers = []
    end

    # Add an archive type to be generated for each of your outputs.
    #
    # @param type [:exe, :"7z", :tar_bz2, :tar_gz, :zip]
    # @return [Project] self
    def add_archive_format(type, &block)
      raise ArgumentError, "Unsupported archive format #{type}" unless ARCHIVERS.has_key? type
      raise ConfigError, "Already have archive format #{type.inspect}" if @archivers.any? {|a| a.type == type }

      archiver = ARCHIVERS[type].new(respond_to?(:project) ? project : self)
      @archivers << archiver

      yield archiver if block_given?

      archiver
    end

    protected
    # @return [Array<Archiver>]
    def active_archivers
      @archivers
    end
  end
end