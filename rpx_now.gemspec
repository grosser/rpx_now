name = "rpx_now"

Gem::Specification.new name, "0.6.24" do |s|
  s.authors = ["Michael Grosser"]
  s.email = %q{grosser.michael@gmail.com}
  s.homepage = "https://github.com/grosser/#{name}"
  s.summary = "Helper to simplify RPX Now user login/creation"
  s.files = `git ls-files lib/ certs/`.split("\n")
  s.add_runtime_dependency "json_pure"
end

