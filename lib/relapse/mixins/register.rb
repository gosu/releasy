require 'forwardable'

module Relapse
  module Mixins
    # Maintains a registry of classes.
    module Register
      include Enumerable
      extend Forwardable

      def_delegators :registered, :[], :each
      def_delegator :registered, :has_key?, :has_type?

      def registered; @registered ||= {}; end

      def register(klass)
        raise "Can't register a class not within this module" unless const_get(klass.name[/[^:]+$/]) == klass
        registered[klass.type] = klass
      end
    end
  end
end