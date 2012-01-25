require 'rubygems'
require 'bundler/setup'
require 'yard'

require File.expand_path('../teststrap', __FILE__)

def run_riot(example, index, filename)
  file_description = "#{filename} example ##{index}"

  context "example ##{index + 1}" do
    if example =~ /#=>/

      code_so_far = ''
      example.scan(/(.*?)#=>\s*([^\n]+)\n?/m).each_with_index do |(code, expected), i|
        code_so_far += code + "\n"

        result = binding.eval(code_so_far, file_description)
        expected = binding.eval("#{code_so_far}\n#{expected}", file_description)
        if expected.is_a? Enumerable
          asserts(code.split("\n").last) { result }.same_elements expected
        else
          asserts(code.split("\n").last) { result }.equals expected
        end
      end
    else
      should('runs without error') { binding.eval(example, file_description); true }
    end
  end
end

def process_method(method)
  if method.has_tag? :example
    context method.name do
      method.tags(:example).each_with_index {|e, i| run_riot e.text, i, "#{method.name} #{e.object}" }
    end
  end
end

context "YARD @examples" do
  YARD.parse('lib/**/*.rb')

  YARD::Registry.all(:class, :module).each do |object|
    context object do
      object.tags(:example).each_with_index {|e, i| run_riot e.text, i, e.object.to_s }
      object.meths(:inherited => false, :included => false).each do |method|
        process_method(method)
        method.tags(:overload).each_with_index {|overload| process_method(overload) }
      end
    end
  end
end

module AlphaChannel
  VERSION = "1.2.2"
end

['README.md'].each do |filename|
  context "#{filename} examples" do
    File.read(filename).scan(/#<<<.*#>>>/m).each_with_index {|e, i| run_riot e, i, filename }
  end
end