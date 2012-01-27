require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Releasy::Mixins::Log do
  setup { Releasy::Mixins::Log }

  asserts(:log_level=, :fish).raises ArgumentError, "Bad log_level: :fish"

  context "included" do
    setup { Object.new.extend topic }

    asserts_topic.respond_to :heading
    asserts_topic.respond_to :info
    asserts_topic.respond_to :warn
  end
end