require "bundler/gem_tasks"

namespace :test do 
  desc "Run all tests in /test"
  task :all do
    Dir["test/**/*_test.rb"].each do |test_path|
      system "ruby #{test_path}"
    end
  end
end