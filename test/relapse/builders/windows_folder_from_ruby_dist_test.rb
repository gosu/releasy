require File.expand_path("helpers/helper", File.dirname(__FILE__))

Dir[File.expand_path("wrappers/ruby-*.7z", $original_path)].each do |path_to_ruby_dist|
  ruby_version = path_to_ruby_dist[/\d\.\d\.\d-p\d+/]
  suffix = "WIN32_FROM_RUBY_DIST_#{ruby_version.tr(".", "_")}"
  folder = File.join(output_path, "test_app_0_1_#{suffix}")

  context "#{Relapse::Builders::WindowsFolderFromRubyDist} for #{ruby_version}" do
    setup { Relapse::Builders::WindowsFolderFromRubyDist.new new_project }

    teardown do
      Dir.chdir $original_path
      Rake::Task.clear
    end

    hookup do
      Dir.chdir project_path
    end

    asserts(:ruby_dist).nil
    asserts(:folder_suffix).equals "WIN32"
    asserts(:generate_tasks).raises Relapse::ConfigError, /ruby_dist not set/
    denies(:gemspecs).empty

    if Gem.win_platform?
      denies(:valid_for_platform?)
    else
      asserts(:valid_for_platform?)
    end

    context "invalid ruby_dist" do
      hookup do
        topic.ruby_dist = "ruby_dist"
      end

      asserts(:generate_tasks).raises Relapse::ConfigError, /ruby_dist not valid/
    end

    context "valid" do
      hookup do
        stub(topic).valid_for_platform?.returns(true) # Need to do this so we can test on all platforms.
        topic.ruby_dist = path_to_ruby_dist
        topic.folder_suffix = suffix
        topic.executable_type = :console
        topic.gemspecs = gemspecs_to_use
        topic.exclude_tcl_tk
        topic.exclude_encoding
        topic.send :generate_tasks
      end

      asserts(:output_path).equals output_path
      asserts(:folder_suffix).equals suffix
      asserts(:ruby_dist).equals path_to_ruby_dist
      asserts("gemspecs correct") { topic.gemspecs == gemspecs_to_use }

      context "tasks" do
        tasks = [
            [ :Task, "build:windows:folder_from_ruby_dist", [folder] ],
            [ :FileTask, '..', [] ], # byproduct of using #directory
            [ :FileTask, output_path, [] ], # byproduct of using #directory
            [ :FileTask, folder, source_files + [path_to_ruby_dist]],
        ]

        test_tasks tasks
      end

      context "generate" do
        hookup { Rake::Task["build:windows:folder_from_ruby_dist"].invoke }

        asserts("files copied to folder") { source_files.all? {|f| same_contents? "#{folder}/src/#{f}", f } }
        asserts("readme copied to folder") { same_contents? "#{folder}/README.txt", "README.txt" }
        asserts("license copied to folder") {  same_contents? "#{folder}/LICENSE.txt", "LICENSE.txt" }

        asserts("test_app.exe has been created") { File.exists?("#{folder}/test_app.exe") }
        denies("console.exe left in folder") { File.exists?("#{folder}/console.exe") }
        denies("windows.exe left in folder") { File.exists?("#{folder}/windows.exe") }

        asserts("ruby.exe left in bin/") { File.exists?("#{folder}/bin/ruby.exe") }
        denies("rubyw.exe left in bin/") { File.exists?("#{folder}/bin/rubyw.exe") }

        asserts("plenty of dlls copied") { Dir["#{folder}/bin/*.dll"].size >= 6 }

        denies("tcl/tk left") { (Dir["#{folder}/**/tk*", "#{folder}/**/tcl*"].reject {|f| f =~ %r[test/unit] }).any? }
        denies("share folder left") { File.exist?("#{folder}/share") }

        if ruby_version =~ /^1\.9\.\d/
          helper(:enc_folder) { "#{folder}/lib/ruby/1.9.1/i386-mingw32/enc" }
          denies("include folder left") { File.exist?("#{folder}/include") }

          asserts("remaining encoding files") { Dir["#{enc_folder}/**/*.so"].map {|f| f[(enc_folder.size + 1)..-1] } }.same_elements %w[encdb.so iso_8859_1.so utf_16le.so trans/single_byte.so trans/transdb.so trans/utf_16_32.so]
        end

        gemspecs_to_use.each do |gemspec|
          name = "#{gemspec.name}-#{gemspec.version}"
          asserts("#{name} gem specification copied") { File.exists? "#{folder}/vendor/specifications/#{name}.gemspec" }
          asserts("#{name} gem folder copied") { File.directory? "#{folder}/vendor/gems/#{name}" }
        end

        if Gem.win_platform?
          asserts("program output") { redirect_bundler_gemfile { %x[#{folder}/test_app.exe] } }.equals "test run!\n"
        end
      end
    end
  end
end