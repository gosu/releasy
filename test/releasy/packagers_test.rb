require File.expand_path("../teststrap", File.dirname(__FILE__))

# Test all packagers at once, since they are pretty much identical.
[
    [:dmg,     Releasy::Packagers::Dmg,      %[GZIP=-9 hdiutil create -fs HFS+ -srcfolder "f" -volname "Test App 0.1" "f.dmg"]],
    [:exe,     Releasy::Packagers::Exe,      %[7za a -mmt -bd -t7z -mx9 -sfx7z.sfx "f.exe" "f"]],
    [:"7z",    Releasy::Packagers::SevenZip, %[7za a -mmt -bd -t7z -mx9 "f.7z" "f"]],
    [:tar_bz2, Releasy::Packagers::TarBzip2, %[7za a -so -mmt -bd -ttar "f.tar" "f" | 7za a -si -bd -tbzip2 -mx9 "f.tar.bz2"]],
    [:tar_gz,  Releasy::Packagers::TarGzip,  %[7za a -so -mmt -bd -ttar "f.tar" "f" | 7za a -si -bd -tgzip -mx9 "f.tar.gz"]],
    [:zip,     Releasy::Packagers::Zip,      %[7za a -mmt -bd -tzip -mx9 "f.zip" "f"]],
].each do |type, packager, command|
  extension = "." + type.to_s.tr("_", ".")

  context packager do
    setup do
      project = Releasy::Project.new
      project.name = "Test App"
      project.version = "0.1"
      packager.new project
    end
    teardown { Rake::Task.clear }

    asserts(:type).equals type
    asserts(:extension).equals extension
    context "" do
      hookup do
        mock(Kernel, :`).with("#{Gem.win_platform? ? "where" : "which"} 7za").returns(true) unless type == :dmg
      end
      asserts(:command, "f").equals command
    end
    asserts(:package, "f").equals "f#{extension}"

    context "setting extension with a . changes package path" do
      hookup { topic.extension = ".wobble" }

      asserts(:extension).equals ".wobble"
      asserts(:package, "f").equals "f.wobble"
    end

    context "setting extension without a . raises an error" do
      asserts(:extension=, "wobble").raises ArgumentError, /extension must be valid/
    end

    context "generated tasks" do
      hookup { topic.send :generate_tasks, "source", "frog", [] }

      tasks = [
          [:FileTask, "frog#{extension}", %w[frog]],
          [:Task, "package:source:#{type}", ["frog#{extension}"]],
      ]

      test_tasks tasks
    end

    context "class" do
      setup { topic.class }

      asserts("#{packager}::TYPE") { topic::TYPE }.equals type

      if type == :exe
        asserts("#{packager}::SFX_NAME") { topic::SFX_NAME }.equals "7z.sfx"
        asserts("#{packager}::SFX_FILE") { topic::SFX_FILE }.equals File.expand_path("bin/7z.sfx", $original_path)
        asserts("sfx file included") { File.exists? topic::SFX_FILE }
      end
    end
  end
end