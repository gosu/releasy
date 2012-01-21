require 'yard'

require File.expand_path('../teststrap', __FILE__)

def run_riot(example, index)
  context "example ##{index + 1}" do
    if example =~ /#=>/
      code_so_far = ''
      example.scan(/(.*?)#=>\s*([^\n]+)\n?/m).each_with_index do |(code, expected), i|
        code_so_far += code + "\n"
        result = eval(code_so_far)
        expected = eval("#{code_so_far}\n#{expected}")
        asserts(code.split("\n").last) { result }.equals expected
      end
    else
      asserts("runs without error") { eval(example); true }
    end
  end
end

context "YARD @examples" do
  YARD.parse('lib/**/*.rb')

  YARD::Registry.all(:class, :module).each do |object|
    context object do
      object.tags(:example).each_with_index {|e, i| run_riot e.text, i }
      object.meths(:inherited => false, :included => false).each do |method|
        if method.has_tag? :example
          context method.name do
            method.tags(:example).each_with_index {|e, i| run_riot e.text, i }
          end
        end
      end
    end
  end
end

module AlphaChannel
  VERSION = "1.2.2"
end

["README.md"].each do |file|
  context "#{file} examples" do
    File.read(file).scan(/#<.*#>/m).each_with_index {|e, i| run_riot e, i }
  end
end