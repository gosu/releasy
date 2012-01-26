require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Releasy::Mixins::Register do
  setup do
    module RegisterTest
     extend Releasy::Mixins::Register
    end
  end

  asserts(:[], :blue).nil
  asserts(:has_type?, :blue).equals false
  asserts(:types).same_elements []
  asserts(:values).same_elements []

  hookup do
    unless defined? NotInModule
      class NotInModule; TYPE = :wibbly; end
      class RegisterTest::Untyped; end
    end
  end

  asserts("trying to register a non-class") { topic.register 12 }.raises TypeError, /Can only register classes/
  asserts("trying to register a class without TYPE, even if in the module") { topic.register topic::Untyped }.raises ArgumentError, /To register, a class must have TYPE defined/

  context "with registered classes (blue and red frogs)" do
    setup do
      module Frogs
        extend Releasy::Mixins::Register
      end
    end

    hookup do
      unless defined? Frogs::BlueFrog
        class Frogs::BlueFrog
          TYPE = :blue # Type must be defined before registering.
          Frogs.register self
        end

        class Frogs::RedFrog
          TYPE = :red # Type must be defined before registering.
          Frogs.register self
        end
      end
    end

    asserts(:[], :blue).equals { Frogs::BlueFrog }
    asserts(:has_type?, :blue).equals true
    asserts(:types).same_elements [:blue, :red]
    asserts(:values).same_elements { [Frogs::BlueFrog, Frogs::RedFrog] }
  end
end