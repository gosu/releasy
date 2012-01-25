module Releasy
module Mixins
  # An object that manages a list of {#gemspecs}
  module HasGemspecs
    # @return [Array<Gem>] List of gemspecs used by the application. Will default to the gems in the `default` Bundler group or, if Bundler isn't used, all gems loaded by rubygems.
    attr_accessor :gemspecs

    protected
    def setup
      @gemspecs = if defined? Bundler
                    Bundler.definition.specs_for([:default]).to_a
                  else
                    Gem.loaded_specs.values
                  end
      super
    end

    protected
    # Don't include binary gems already in the .app or bundler, since it will get confused.
    def vendored_gem_names(ignored_gems); (gemspecs.map(&:name) - ignored_gems).sort; end

    protected
    def copy_gems(gems, destination)
      puts "Copying source gems from system" if project.verbose?

      gems_dir = "#{destination}/gems"
      specs_dir = "#{destination}/specifications"
      mkdir_p gems_dir
      mkdir_p specs_dir

      gems.each do |gem|
        spec = gemspecs.find {|g| g.name == gem }
        gem_dir = spec.full_gem_path
        puts "Copying gem: #{spec.name} #{spec.version}" if project.verbose?
        cp_r gem_dir, gems_dir
        spec_file = File.expand_path("../../specifications/#{File.basename gem_dir}.gemspec", gem_dir)
        cp_r spec_file, specs_dir
      end
    end
  end
end
end