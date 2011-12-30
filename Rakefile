require "rubygems"
require "bundler/gem_tasks"

desc "Run all tests in /test"
task :test do
  Dir["test/**/*_test.rb"].each do |test_path|
    system "ruby #{test_path}"
  end
end