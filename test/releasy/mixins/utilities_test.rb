require File.expand_path("../../teststrap", File.dirname(__FILE__))

context Releasy::Mixins::Utilities do
  setup { Object.new.extend Releasy::Mixins::Utilities }

  context "#execute_command" do
    asserts("executing command that exists") do
      mock(IO).popen("hello").yields StringIO.new("Hello!\nHello!\n")
      mock(topic).info("hello")
      mock(topic).info("Hello!").twice
      topic.send :execute_command, "hello"
    end.equals true

    asserts("executing command that doesn't exist") do
      mock(IO).popen("hello") { raise Errno::ENOENT }
      mock(topic).info("hello")
      topic.send :execute_command, "hello"
    end.equals false
  end

  context "#command_available?" do
    context "on Windows" do
      should "return true if available" do
        stub(Releasy).win_platform?.returns true
        mock(Kernel, :`).with("where command").returns "/frog/command"
        mock(topic).kernel_result.returns 0
        topic.send(:command_available?, "command")
      end.equals true

      should "return false if not available" do
        stub(Releasy).win_platform?.returns true
        mock(Kernel, :`).with("where command").returns ""
        mock(topic).kernel_result.returns 1
        topic.send(:command_available?, "command")
      end.equals false
    end

    context "not on Windows" do
      should "return true if available" do
        stub(Releasy).win_platform?.returns false
        mock(Kernel, :`).with("which command").returns "/frog/command"
        mock(topic).kernel_result.returns 0
        topic.send(:command_available?, "command")
      end.equals true

      should "return false if not available" do
        stub(Releasy).win_platform?.returns false
        mock(Kernel, :`).with("which command").returns ""
        mock(topic).kernel_result.returns 256
        topic.send(:command_available?, "command")
      end.equals false
    end
  end
end