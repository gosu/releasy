require File.expand_path("../teststrap", File.dirname(__FILE__))

# Test all archivers at once, since they are pretty much identical.
[
    [:"7z",    Relapse::Archivers::SevenZip, %[7z a -mmt -bd -t7z "f.7z" "f"]],
    [:tar_bz2, Relapse::Archivers::TarBzip2, %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tbzip2 "f.tar.bz2"]],
    [:tar_gz,  Relapse::Archivers::TarGzip,  %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tgzip "f.tar.gz"]],
    [:zip,     Relapse::Archivers::Zip,      %[7z a -mmt -bd -tzip "f.zip" "f"]],
].each do |identifier, archiver, command|
  extension = identifier.to_s.tr("_", ".")

  context archiver do
    teardown { Rake::Task.clear }

    context "class" do
      setup { archiver }

      asserts(:identifier).equals identifier
    end

    context "instance" do
      setup { archiver.new Object.new }

      asserts(:identifier).equals identifier
      asserts(:extension).equals extension
      asserts(:command, "f").equals command
      asserts(:package, "f").equals "f.#{extension}"

      context "generated tasks" do
        hookup { topic.create_tasks "source", "frog" }

        tasks = [
            [:FileTask, "frog.#{extension}", %w[frog]],
            [:Task, "package:source:#{identifier}", ["frog.#{extension}"]],
        ]

        test_tasks tasks
      end
    end
  end
end