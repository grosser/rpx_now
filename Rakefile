require 'rubygems'
require 'echoe'

desc "Run all specs in spec directory"
task :default do |t|
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

#Gemspec
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    porject_name = 'rpx_now'
    gem.name = porject_name
    gem.summary = "Helper to simplify RPX Now user login/creation"
    gem.email = "grosser.michael@gmail.com"
    gem.homepage = "http://github.com/grosser/#{porject_name}"
    gem.authors = ["Michael Grosser"]
    gem.add_dependency ['activesupport']
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :update_gemspec => [:manifest, :build_gemspec]