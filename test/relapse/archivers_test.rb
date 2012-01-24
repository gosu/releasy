require File.expand_path("../teststrap", File.dirname(__FILE__))

# Test all archivers at once, since they are pretty much identical.
[
    [:dmg,     Relapse::Archivers::Dmg,      %[GZIP=-9 hdiutil create -fs HFS+ -srcfolder "f" -volname "Test App 0.1" "f.dmg"]],
    [:exe,     Relapse::Archivers::Exe,      %[7z a -mmt -bd -t7z -mx9 -sfx7z.sfx "f.exe" "f"]],
    [:"7z",    Relapse::Archivers::SevenZip, %[7z a -mmt -bd -t7z -mx9 "f.7z" "f"]],
    [:tar_bz2, Relapse::Archivers::TarBzip2, %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tbzip2 -mx9 "f.tar.bz2"]],
    [:tar_gz,  Relapse::Archivers::TarGzip,  %[7z a -so -mmt -bd -ttar "f.tar" "f" | 7z a -si -bd -tgzip -mx9 "f.tar.gz"]],
    [:zip,     Relapse::Archivers::Zip,      %[7z a -mmt -bd -tzip -mx9 "f.zip" "f"]],
].each do |type, archiver, command|
  extension = "." + type.to_s.tr("_", ".")

  context archiver do
    setup do
      project = Relapse::Project.new
      project.name = "Test App"
      project.version = "0.1"
      archiver.new project
    end
    teardown { Rake::Task.clear }

    asserts(:type).equals type
    asserts(:extension).equals extension
    asserts(:command, "f").equals command
    asserts(:package, "f").equals "f#{extension}"

    context "setting extension with a . changes package path" do
      hookup { topic.extension = ".wobble" }

      asserts(:extension).equals ".wobble"
      asserts(:package, "f").equals "f.wobble"
    end

    context "setting extension without a . still adds one" do
      hookup { topic.extension = "wobble" }

      asserts(:extension).equals "wobble"
      asserts(:package, "f").equals "f.wobble"
    end

    context "generated tasks" do
      hookup { topic.send :generate_tasks, "source", "frog" }

      tasks = [
          [:FileTask, "frog#{extension}", %w[frog]],
          [:Task, "package:source:#{type}", ["frog#{extension}"]],
      ]

      test_tasks tasks
    end

    context "class" do
      setup { topic.class }

      asserts("#{archiver}::TYPE") { topic::TYPE }.equals type

      if type == :exe
        asserts("#{archiver}::SFX_NAME") { topic::SFX_NAME }.equals "7z.sfx"
        asserts("#{archiver}::SFX_FILE") { topic::SFX_FILE }.equals File.expand_path("bin/7z.sfx", $original_path)
        asserts("sfx file included") { File.exists? topic::SFX_FILE }
      end
    end
  end
end