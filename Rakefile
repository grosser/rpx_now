task :default => :spec
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--backtrace --color'
end

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = 'slayer-rpx_now'
    gem.summary = "Helper to simplify RPX Now user login/creation"
    gem.email = "github@vlad.org.ua"
    gem.homepage = "http://github.com/slayer/#{gem.name}"
    gem.authors = ["Michael Grosser", "Vlad Moskovets"]
    gem.add_dependency ['json_pure']
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
