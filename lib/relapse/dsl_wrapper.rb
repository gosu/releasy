module Relapse
  # Wraps an object and redirects public methods to it, to allow for a terse, block-based API.
  #
  # * Safer alternative to running Object#instance_eval directly, since protected/private methods and instance variables are not exposed.
  # * Less wordy than a Object#tap-based system, such as `object.tap {|o| o.fish = 5; o.run }`
  #
  # @example
  #     # To create a DSL block for a given object.
  #     class Cheese
  #       attr_accessor :value
  #       attr_accessor :list
  #       def initialize; @value = 0; @list = []; end
  #       def run; @list.map {|i| i + 7 }; end
  #     end
  #
  #     object = Cheese.new
  #     Relapse::DSLWrapper.new(object).instance_eval do
  #       list [1, 2, 3]      # Calls object.list = [1, 2, 3]
  #       list << 4           # Calls object.list << 4
  #       value 5             # Calls object.value = 5
  #       value list.size     # Calls object.value = object.list.size
  #       run                 # Calls object.run
  #     end
  class DSLWrapper
    # Object that the DSLWrapper object is redirecting to.
    attr_reader :owner

    # @param owner [Object] Object to redirect the public methods of.
    def initialize(owner)
      @owner = owner

      metaclass = class << self; self; end

      (@owner.public_methods - Object.public_instance_methods).each do |target_method|
        redirection_method = target_method.to_s.chomp('=').to_sym

        metaclass.class_eval do
          define_method redirection_method do |*args, &block|
            if @owner.respond_to? "#{redirection_method}=" and (args.any? or not @owner.respond_to? redirection_method)
              # Has a setter and we are passing argument(s) or if we haven't got a corresponding getter.
              @owner.send "#{redirection_method}=", *args, &block
            elsif @owner.respond_to? redirection_method
              # We have a getter or general method
              @owner.send redirection_method, *args, &block
            else
              # Should never reach here, but let's be paranoid.
              raise NoMethodError, "#{owner} does not have a public method, ##{redirection_method}"
            end
          end
        end
      end
    end

    def method_missing(meth, *args, &block)
      raise NoMethodError, "#{owner} does not have a public method, ##{meth}"
    end
  end
end