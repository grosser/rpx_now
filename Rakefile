require 'rubygems'
require 'spec'

desc "Run all specs in spec directory"
task :test do |t|
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end