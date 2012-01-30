require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Releasy::Mixins::Utilities do
  setup { Object.new.extend Releasy::Mixins::Utilities }

  context "#execute_command" do
    asserts_topic.respond_to :execute_command
  end

  context "#command_available?" do
    context "on Windows" do
      should "return true if available" do
        stub(Releasy).win_platform?.returns true
        mock(Kernel, :`).with("where command").returns true
        topic.send(:command_available?, "command")
      end.equals true

      should "return false if not available" do
        stub(Releasy).win_platform?.returns true
        mock(Kernel, :`).with("where command").returns nil
        topic.send(:command_available?, "command")
      end.equals false
    end

    context "not on Windows" do
      should "return true if available" do
        stub(Releasy).win_platform?.returns false
        mock(Kernel, :`).with("which command").returns true
        topic.send(:command_available?, "command")
      end.equals true

      should "return false if not available" do
        stub(Releasy).win_platform?.returns false
        mock(Kernel, :`).with("which command").returns nil
        topic.send(:command_available?, "command")
      end.equals false
    end
  end
end