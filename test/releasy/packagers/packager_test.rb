require File.expand_path("../../teststrap", File.dirname(__FILE__))


context Releasy::Packagers::Packager do
  helper(:project) { @project ||= Object.new }

  setup do
    Releasy::Mixins::Utilities.seven_zip_command = nil
    Class.new(Releasy::Packagers::Packager) do
      const_set :TYPE, :test
      const_set :DEFAULT_EXTENSION, '.bleh'
    end.new project
  end

  asserts(:project).equals { project }
  asserts(:type).equals :test
  asserts(:extension).equals ".bleh"
  asserts(:extension=, 12).raises TypeError, /extension must be a String/
  asserts(:extension=, "frog").raises ArgumentError, /extension must be valid/
  asserts(:package, "fish").equals "fish.bleh"

  asserts_topic.respond_to :checksum
  asserts_topic.respond_to :generate_tasks
  asserts_topic.respond_to :archive

  context "#seven_zip_command" do    context "on Windows" do
      context "7za command available" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns true
          mock(Kernel, :`).with("where 7za").returns "C:/bin/7za"
          dont_allow(Kernel, :`).with("where 7z")
          topic.send :seven_zip_command
        end.equals "7za"
      end

      context "7za not available, but 7z is" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns true
          mock(Kernel, :`).with("where 7za").returns ""
          mock(Kernel, :`).with("where 7z").returns "C:/bin/7z"
          topic.send :seven_zip_command
        end.equals "7z"
      end

      context "no 7z installation" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns true
          mock(Kernel, :`).with("where 7za").returns ""
          mock(Kernel, :`).with("where 7z").returns ""
          topic.send :seven_zip_command
        end.equals %["#{File.expand_path "../../../../bin/7za.exe", __FILE__}"]
      end
    end

    context "not on Windows" do
      context "7za command available" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns false
          mock(Kernel, :`).with("which 7za").returns "/bin/7za"
          dont_allow(Kernel, :`).with("which 7z")
          topic.send :seven_zip_command
        end.equals "7za"
      end

      context "7za not available, but 7z is" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns false
          mock(Kernel, :`).with("which 7za").returns ""
          mock(Kernel, :`).with("which 7z").returns "/bin/7z"
          topic.send :seven_zip_command
        end.equals "7z"
      end

      context "no 7z installation" do
        asserts :seven_zip_command do
          stub(Releasy).win_platform?.returns false
          mock(Kernel, :`).with("which 7za").returns ""
          mock(Kernel, :`).with("which 7z").returns ""
          topic.send :seven_zip_command
        end.raises Releasy::CommandNotFoundError, /Failed to find 7-ZIP/
      end
    end
  end
end