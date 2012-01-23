require File.expand_path("../../teststrap", File.dirname(__FILE__))

require "relapse/cli"

module Riot
  class CommandPutsMacro < AssertionMacro
    register :command_puts

    def evaluate(argv, expected)
      $puts_string = nil
      Relapse::Cli.run argv
      if $puts_string =~ expected
        pass ": command #{argv} expected to print #{expected.inspect} and got #{$puts_string.inspect}"
      else
        fail ": command #{argv} expected to print #{expected.inspect}, but got #{$puts_string.inspect}"
      end
    end

    def devaluate(argv, expected); raise NotImplementedError; end
  end

  class CommandExitsAndPutsMacro < CommandPutsMacro
    register :command_exits_and_puts

    def evaluate(argv, expected)
      $puts_string = nil
      begin
        Relapse::Cli.run argv
        fail ": command #{argv} didn't exit"
      rescue SystemExit
        if $puts_string =~ expected
          pass ": command #{argv} expected to print #{expected.inspect} and got #{$puts_string.inspect}"
        else
          fail ": command #{argv} expected to print #{expected.inspect}, but got #{$puts_string.inspect}"
        end
      end
    end
  end
end

context "relapse install-sfx" do
  context "on Windows" do
    should "refuse on windows" do
      mock(Gem).win_platform?.returns true
      any_instance_of(Cri::CommandDSL) {|o| stub(o).puts {|s| $puts_string = s } }
      dont_allow(FileUtils).cp

      ["install-sfx"]
    end.command_exits_and_puts /only required when not on a Windows platform/
  end

  context "on non-Windows" do

    helper :stubs do |which_7z|
      mock(Gem).win_platform?.returns false
      any_instance_of(Cri::CommandDSL) do |o|
        stub(o).puts {|s| $puts_string = s }
        stub(o, :`).with("which 7z").returns which_7z
      end
    end

    should "refuse unless 7z installed" do
      stubs ""
      dont_allow(FileUtils).cp

      ["install-sfx"]
    end.command_exits_and_puts /7z \(p7zip\) not installed; install it before trying to use this command/

    should "refuse when file exists" do
      stubs "/usr/bin/7z"
      stub(File).exists?("/usr/lib/p7zip/7z.sfx").returns true
      dont_allow(FileUtils).cp

      ["install-sfx"]
    end.command_exits_and_puts /already exists; no need to install it again/

    should "copy sfx file" do
      stubs "/usr/bin/7z"
      stub(File).exists?("/usr/lib/p7zip/7z.sfx").returns false
      stub(FileUtils).cp(File.expand_path("bin/7z.sfx"), "/usr/lib/p7zip") { raise Errno::ENOENT }
      any_instance_of(Cri::CommandDSL) do |o|
        mock(o).exec(%[sudo cp "#{File.expand_path('bin/7z.sfx')}" "/usr/lib/p7zip"])
      end

      ["install-sfx"]
    end.command_puts %r[7z.sfx copied to /usr/lib/p7zip]
  end
end