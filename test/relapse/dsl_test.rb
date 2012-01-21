require File.expand_path("../teststrap", File.dirname(__FILE__))

context Relapse::Dsl do
  helper :owner_class do
    # Can't mock, since the Dsl methods are created when it is created.
    Owner = Class.new do
      def initialize; @frog = @fish = 5; end
      def frog; @frog; end # Won't be redirected.
      def fish; @fish; end # Won't be redirected.
      def fish=(fish); @fish = fish; end # Will be redirected as :fish
      def add_cheese(a, b); 99; end # Will be redirected as :add_cheese
      def add_peas(a, &block); yield :peas; end # Will be redirected as :add_peas with a block
    end
  end

  helper(:owner) { @owner ||= owner_class.new }

  setup { Relapse::Dsl.new owner }

  asserts(:public_methods, false).same_elements [:fish, :add_cheese, :owner, :add_peas]
  asserts(:owner).equals { owner }
  asserts(:frog, 25).raises NoMethodError
  asserts(:fish=).raises NoMethodError
  asserts(:fish=, 5).raises NoMethodError

  should "redirect a setter" do
    mock(owner, :fish=).with(5).returns(5)
    topic.fish(5) == 5
  end

  should "redirect a (non-setter) method with args" do
    mock(owner).add_cheese(1, 2).returns(99)
    topic.add_cheese(1, 2) == 99
  end

  should "redirect a block" do
    mock(owner).add_peas(1).yields(:knees)
    yielded = nil
    topic.add_peas(1) do |arg|
      yielded = arg
    end
    yielded == :knees
  end
end