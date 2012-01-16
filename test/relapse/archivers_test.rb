require File.expand_path("../teststrap", File.dirname(__FILE__))

# Test all archivers at once, since they are pretty much identical.
[
    [:exe,     Relapse::Archivers::Exe,      %[7z a -mmt -bd -t7z -sfx7z.sfx "f.exe" "f"]],
    [:"7z",    Relapse::Archivers::SevenZip, %[7z a -mmt -bd -t7z "f.7z" "f"]],
    [:tar_bz2, Relapse::Archivers::TarBzip2, %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tbzip2 "f.tar.bz2"]],
    [:tar_gz,  Relapse::Archivers::TarGzip,  %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tgzip "f.tar.gz"]],
    [:zip,     Relapse::Archivers::Zip,      %[7z a -mmt -bd -tzip "f.zip" "f"]],
].each do |type, archiver, command|
  extension = "." + type.to_s.tr("_", ".")

  context archiver do
    setup { archiver.new Object.new }
    teardown { Rake::Task.clear }

    asserts(:type).equals type
    asserts(:extension).equals extension
    asserts(:command, "f").equals command
    asserts(:package, "f").equals "f#{extension}"

    context "generated tasks" do
      hookup { topic.generate_tasks "source", "frog" }

      tasks = [
          [:FileTask, "frog#{extension}", %w[frog]],
          [:Task, "package:source:#{type}", ["frog#{extension}"]],
      ]

      test_tasks tasks
    end

    context "class" do
      setup { topic.class }

      asserts(:type).equals type

      if type == :exe
        asserts("#{archiver}::SFX_NAME") { topic::SFX_NAME }.equals "7z.sfx"
        asserts("#{archiver}::SFX_FOLDER") { topic::SFX_FOLDER }.equals "/usr/lib/p7zip"
        asserts("sfx file included") { File.exists? topic::SFX_FILE }
      end
    end
  end
end