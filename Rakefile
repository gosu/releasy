require 'rake/testtask'

desc "Run all tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = "test/**/*_test.rb"
    t.verbose = false
  end
end

task :yard do
  system "yard doc"
end

task :default => :test