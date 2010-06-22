begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "mongoid_slug"
    gemspec.summary = "Generates a URL slug in a Mongoid model"
    gemspec.description = "Mongoid Slug generates a URL slug/permalink based on a field in a Mongoid model."
    gemspec.add_runtime_dependency("mongoid", ["~>2.0.0.beta7"])
    gemspec.files = Dir.glob("lib/**/*") + %w(LICENSE README.rdoc)
    gemspec.require_path = 'lib'
    gemspec.email = "code@papercavalier.com"
    gemspec.homepage = "http://github.com/papercavalier/mongoid-slug"
    gemspec.authors = ["Hakan Ensari"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
