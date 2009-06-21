# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rpx_now}
  s.version = "0.5.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Grosser"]
  s.date = %q{2009-06-21}
  s.email = %q{grosser.michael@gmail.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "CHANGELOG",
    "MIGRATION",
    "README.markdown",
    "Rakefile",
    "VERSION.yml",
    "certs/ssl_cert.pem",
    "init.rb",
    "lib/rpx_now.rb",
    "lib/rpx_now/contacts_collection.rb",
    "lib/rpx_now/user_integration.rb",
    "lib/rpx_now/user_proxy.rb",
    "rpx_now.gemspec",
    "spec/fixtures/get_contacts_response.json",
    "spec/rpx_now/contacts_collection_spec.rb",
    "spec/rpx_now/user_proxy_spec.rb",
    "spec/rpx_now_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/grosser/rpx_now}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Helper to simplify RPX Now user login/creation}
  s.test_files = [
    "spec/rpx_now_spec.rb",
    "spec/rpx_now/contacts_collection_spec.rb",
    "spec/rpx_now/user_proxy_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
  end
end
