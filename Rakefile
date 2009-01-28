require 'rubygems'
require 'echoe'

desc "Run all specs in spec directory"
task :test do |t|
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

#Gemspec
porject_name = 'rpx_now'
Echoe.new(porject_name , '0.3') do |p|
  p.description    = "Helper to simplify RPX Now user login/creation"
  p.url            = "http://github.com/grosser/#{porject_name}"
  p.author         = "Michael Grosser"
  p.email          = "grosser.michael@gmail.com"
  p.dependencies   = %w[activesupport]
end

task :update_gemspec => [:manifest, :build_gemspec]