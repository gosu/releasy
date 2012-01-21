require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Relapse::Mixins::Register do
  setup do
    module Test
     extend Relapse::Mixins::Register
    end
  end

  asserts(:[], :blue).nil
  asserts(:has_type?, :blue).equals false
  asserts(:types).same_elements []
  asserts(:values).same_elements []

  helper :cat do
    class Cat
      def self.type; :wibbly; end
      Test.register self
    end
  end

  asserts("Trying to register a class not within the module") { cat }.raises ArgumentError, /Can't register a class not within this module/

  context "with registered classes (blue and red frogs)" do
    setup do
      module Frogs
        extend Relapse::Mixins::Register
      end
    end

    hookup do
      class Frogs::BlueFrog
        def self.type; :blue; end # Type must be defined before registering.
        Frogs.register self
      end

      class Frogs::RedFrog
        def self.type; :red; end # Type must be defined before registering.
        Frogs.register self
      end
    end

    asserts(:[], :blue).equals { Frogs::BlueFrog }
    asserts(:has_type?, :blue).equals true
    asserts(:types).same_elements [:blue, :red]
    asserts(:values).same_elements { [Frogs::BlueFrog, Frogs::RedFrog] }
  end
end