require 'bundler/setup'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'


Dir.glob('lib/tasks/*.rake').each { |r| load r }

RSpec::Core::RakeTask.new(:spec)

task default: :spec
