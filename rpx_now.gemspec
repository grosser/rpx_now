# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rpx_now}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Grosser"]
  s.date = %q{2009-02-13}
  s.description = %q{Helper to simplify RPX Now user login/creation}
  s.email = %q{grosser.michael@gmail.com}
  s.extra_rdoc_files = ["CHANGELOG", "lib/rpx_now.rb", "README.markdown"]
  s.files = ["Manifest", "CHANGELOG", "lib/rpx_now.rb", "spec/rpx_now_spec.rb", "spec/spec_helper.rb", "init.rb", "Rakefile", "README.markdown", "rpx_now.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/grosser/rpx_now}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Rpx_now", "--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rpx_now}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Helper to simplify RPX Now user login/creation}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
  end
end
