require File.expand_path("../../teststrap", File.dirname(__FILE__))


context Releasy::Packagers::Packager do
  helper(:project) { @project ||= Object.new }

  setup do
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

  asserts(:respond_to?, :checksum)
  asserts(:respond_to?, :generate_tasks)
  asserts(:respond_to?, :archive)

  context "#seven_zip_command" do
    helper(:setup) do |windows, za, z = nil|
      stub(Releasy).win_platform?.returns windows
      find = windows ? "where" : "which"
      mock(Kernel, :`).with("#{find} 7za").returns za
      mock(Kernel, :`).with("#{find} 7z").returns z unless z.nil?
    end

    context "on Windows" do
      context "7za command available" do
        asserts :seven_zip_command do
          setup true, true
          topic.send :seven_zip_command
        end.equals "7za"
      end

      context "7za not available, but 7z is" do
        asserts :seven_zip_command do
          setup true, false, true
          topic.send :seven_zip_command
        end.equals "7z"
      end

      context "no 7z installation" do
        asserts :seven_zip_command do
          setup true, false, false
          topic.send :seven_zip_command
        end.equals %["#{File.expand_path "../../../../bin/7za.exe", __FILE__}"]
      end
    end

    context "not on Windows" do
      context "7za command available" do
        asserts :seven_zip_command do
          setup false, true
          topic.send :seven_zip_command
        end.equals "7za"
      end

      context "7za not available, but 7z is" do
        asserts :seven_zip_command do
          setup false, false, true
          topic.send :seven_zip_command
        end.equals "7z"
      end

      context "no 7z installation" do
        asserts :seven_zip_command do
          setup false, false, false
          topic.send :seven_zip_command
        end.raises Releasy::CommandNotFoundError, /Failed to find 7-ZIP/
      end
    end
  end
end