require 'forwardable'

module Releasy
  module Mixins
    # Maintains a registry of classes within a module.
    #
    # @example
    #   module Frogs
    #     extend Releasy::Mixins::Register
    #   end
    #
    #   class Frogs::BlueFrog
    #     TYPE = :blue # Type must be defined before registering.
    #     Frogs.register self
    #   end
    #
    #   class Frogs::RedFrog
    #     TYPE = :red # Type must be defined before registering.
    #     Frogs.register self
    #   end
    #
    #   Frogs[:blue]          #=> Frogs::BlueFrog
    #   Frogs.has_type? :blue #=> true
    #   Frogs.types           #=> [:blue, :red]
    #   Frogs.values          #=> [Frogs::BlueFrog, Frogs::RedFrog]
    module Register
      include Enumerable
      extend Forwardable

      def_delegators :registered, :[], :each, :values
      def_delegator :registered, :has_key?, :has_type?
      def_delegator :registered, :keys, :types

      # Register a class with this register of classes of that type.
      # @param klass [Object] Object, which is defined within the namespace being registered with.
      def register(klass)
        raise TypeError, "Can only register classes" unless klass.is_a? Class
        raise ArgumentError, "Can't register a class not within this module" unless klass.name.split('::')[0...-1].join('::') == name
        raise ArgumentError, "To register, a class must have TYPE defined" unless klass.const_defined? :TYPE
        registered[klass::TYPE] = klass
      end

      protected
      def registered; @registered ||= {}; end
    end
  end
end