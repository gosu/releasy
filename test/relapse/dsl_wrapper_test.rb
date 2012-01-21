require File.expand_path("../teststrap", File.dirname(__FILE__))

context Relapse::DSLWrapper do
  helper :owner_class do
    # Can't simply stub, since the DSLWrapper redirection methods are created when from the owner's methods.
    Owner = Class.new do
      def frog; end
      def fish; end
      def fish=(fish); end
      def knees=(knees); end
      def add_cheese(a, b); end
      def add_peas(a, &block); end
    end
  end

  helper(:owner) { @owner ||= owner_class.new }

  setup { Relapse::DSLWrapper.new owner }

  asserts(:public_methods, false).same_elements [:frog, :fish, :add_cheese, :owner, :add_peas, :knees, :method_missing]
  asserts(:owner).equals { owner }

  asserts("a method that doesn't exist on the owner") { topic.wibble }.raises NoMethodError, / does not have a public method, #wibble/

  should "redirect to a setter, that has no corresponding getter, even if no arguments are passed" do
    topic.knees
  end.raises ArgumentError

  should "redirect to a getter, that has no corresponding setter, even if arguments are passed" do
    topic.frog 25
  end.raises ArgumentError

  should "redirect a getter (that has no corresponding setter)" do
    mock(owner, :frog).returns(5)
    topic.frog == 5
  end

  should "redirect a setter (that has no corresponding getter)" do
    mock(owner, :knees=).with(1).returns(5)
    topic.knees(1) == 5
  end

  should "redirect a getter (that has a corresponding setter)" do
    mock(owner, :fish).returns(5)
    topic.fish == 5
  end

  should "redirect a setter (that has a corresponding getter)" do
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