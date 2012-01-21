module Relapse
  # Wraps an object and redirects public methods to it.
  # @example
  #     # To create a DSL block for a given object:
  #     Dsl.new(object).instance_eval &block
  class Dsl
    # Object that the Dsl object is redirecting to.
    attr_reader :owner

    # @param owner [Object] Object to redirect the public methods of.
    def initialize(owner)
      @owner = owner

      metaclass = class << self; self; end

      (@owner.public_methods - Object.public_instance_methods).each do |meth|
        next if @owner.method(meth).arity == 0

        metaclass.class_eval do
          define_method meth.to_s.chomp("=").to_sym do |*args, &block|
            @owner.send meth, *args, &block
          end
        end
      end
    end
  end
end