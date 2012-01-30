require File.expand_path("helper", File.dirname(__FILE__))

def acts_like_a_builder
  context Releasy::Builders::Builder do
    asserts_topic.kind_of Releasy::Builders::Builder

    asserts(:respond_to?, :setup)
    asserts(:respond_to?, :task_group)
    asserts(:respond_to?, :folder)

    asserts(:type).equals { topic.class::TYPE }
    asserts(:suffix).equals { topic.class::DEFAULT_FOLDER_SUFFIX }
    asserts("valid_for_platform? returns a Boolean") { [true, false].include? topic.valid_for_platform? }

    asserts(:project).is_a? Releasy::Project
    asserts(:suffix).is_a? String

    asserts(:suffix=, 5).raises TypeError

    context "#suffix=" do
      hookup { topic.suffix = "hello" }
      asserts(:suffix).equals "hello"
    end

    context "#copy_files_relative" do
      should "copy files to their relative directories" do
        mock(topic).mkdir_p "d/.", :verbose => false
        mock(topic).cp "a", "d/.", :verbose => false
        mock(topic).mkdir_p "d/b", :verbose => false
        mock(topic).cp "b/c", "d/b", :verbose => false
        topic.send :copy_files_relative, %w[a b/c], 'd'
      end
    end
  end
end
