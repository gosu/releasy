require 'forwardable'

module Relapse
  module Mixins
    # Maintains a registry of classes.
    module Register
      include Enumerable
      extend Forwardable

      def_delegators :registered, :[], :each
      def_delegator :registered, :has_key?, :has_type?

      # Register a class with this register of classes of that type.
      def register(klass)
        raise "Can't register a class not within this module" unless const_get(klass.name[/[^:]+$/]) == klass
        registered[klass.type] = klass
      end

      protected
      def registered; @registered ||= {}; end
    end
  end
end