# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{slayer-rpx_now}
  s.version = "0.6.25"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Grosser", "Vlad Moskovets"]
  s.date = %q{2011-08-12}
  s.email = %q{github@vlad.org.ua}
  s.files = [
    ".gitignore",
     "CHANGELOG",
     "Gemfile",
     "Gemfile.lock",
     "MIGRATION",
     "Rakefile",
     "Readme.md",
     "VERSION",
     "certs/ssl_cert.pem",
     "init.rb",
     "lib/rpx_now.rb",
     "lib/rpx_now/api.rb",
     "lib/rpx_now/contacts_collection.rb",
     "lib/rpx_now/user_integration.rb",
     "lib/rpx_now/user_proxy.rb",
     "rpx_now.gemspec",
     "slayer-rpx_now.gemspec",
     "spec/fixtures/get_contacts_response.json",
     "spec/integration/mapping_spec.rb",
     "spec/rpx_now/api_spec.rb",
     "spec/rpx_now/contacts_collection_spec.rb",
     "spec/rpx_now/user_proxy_spec.rb",
     "spec/rpx_now_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/slayer/slayer-rpx_now}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.7.2}
  s.summary = %q{Helper to simplify RPX Now user login/creation}
  s.test_files = [
    "spec/rpx_now/user_proxy_spec.rb",
     "spec/rpx_now/api_spec.rb",
     "spec/rpx_now/contacts_collection_spec.rb",
     "spec/rpx_now_spec.rb",
     "spec/spec_helper.rb",
     "spec/integration/mapping_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json_pure>, [">= 0"])
    else
      s.add_dependency(%q<json_pure>, [">= 0"])
    end
  else
    s.add_dependency(%q<json_pure>, [">= 0"])
  end
end

