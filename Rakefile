require 'rubygems'

desc "Run all specs in spec directory"
task :default do |t|
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

begin
  require 'jeweler'
  project_name = 'rpx_now'

  Jeweler::Tasks.new do |gem|
    gem.name = project_name
    gem.summary = "Helper to simplify RPX Now user login/creation"
    gem.email = "grosser.michael@gmail.com"
    gem.homepage = "http://github.com/grosser/#{project_name}"
    gem.authors = ["Michael Grosser"]
    gem.add_dependency ['json_pure']
    gem.rubyforge_project = 'rpx-now'
  end

  # fake task so that rubyforge:release works
  task :rdoc do
    `mkdir rdoc`
    `echo documentation is at http://github.com/grosser/#{project_name} > rdoc/README.rdoc`
  end

  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
