require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Releasy::Mixins::Log do
  setup { Releasy::Mixins::Log }

  asserts(:log_level=, :fish).raises ArgumentError, "Bad log_level: :fish"

  context "included" do
    setup { Object.new.extend topic }

    asserts('#heading') { topic.respond_to?(:heading, true) }.equals true
    asserts('#info') { topic.respond_to?(:info, true) }.equals true
    asserts('#warn') { topic.respond_to?(:warn, true) }.equals true
  end
end