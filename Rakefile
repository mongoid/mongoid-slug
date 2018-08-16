require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks name: 'mongoid-slug'

desc 'Run all specs in spec directory'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task default: %i[rubocop spec]
