module Relapse
module Mixins
  module HasGemspecs
    # @return [Array<Gem>] List of gemspecs used by the application, which should usually be: Bundler.definition.gems_for([:default])
    attr_accessor :gemspecs

    protected
    def setup
      @gemspecs = []
      super
    end

    protected
    # Don't include binary gems already in the .app or bundler, since it will get confused.
    def vendored_gem_names(ignored_gems); (gemspecs.map(&:name) - ignored_gems).sort; end

    protected
    def copy_gems(gems, destination)
      puts "Copying gems into app" if project.verbose?
      mkdir_p destination
      gems.each do |gem|
        gemspec = gemspecs.find {|g| g.name == gem }
        gem_path = gemspec.full_gem_path
        puts "Copying gem: #{File.basename gem_path}" if project.verbose?
        cp_r gem_path, File.join(destination, gem)
      end
    end
  end
end
end