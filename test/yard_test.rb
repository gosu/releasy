require 'yard'

require File.expand_path('../teststrap', __FILE__)

def run_riot(example)
  asserts("example runs without error") { eval(example); true }
end

context "YARD @examples" do
  YARD.parse('lib/**/*.rb')

  YARD::Registry.all(:class, :module).each do |object|
    context object do
      object.tags(:example).each {|e| run_riot e.text }
      object.meths(:inherited => false, :included => false).each do |method|
        if method.has_tag? :example
          context method.name do
            method.tags(:example).each {|e| run_riot e.text }
          end
        end
      end
    end
  end
end

["README.md"].each do |file|
  context "#{file} examples" do
    module AlphaChannel
      VERSION = "1.2.2"
    end
    File.read(file).scan(/#EXAMPLE_START.*#EXAMPLE_END/m) {|e| run_riot e }
  end
end