require 'rake/testtask'

# Tasks
namespace :foreman_opennebula do
  namespace :example do
    desc 'Example Task'
    task task: :environment do
      # Task goes here
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanOpennebula'
  Rake::TestTask.new(:foreman_opennebula) do |t|
    test_dir = File.expand_path('../../test', __dir__)
    t.libs << 'test'
    t.libs << test_dir
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end
end

namespace :foreman_opennebula do
  task :rubocop do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_opennebula) do |task|
        task.patterns = ["#{ForemanOpennebula::Engine.root}/app/**/*.rb",
                         "#{ForemanOpennebula::Engine.root}/lib/**/*.rb",
                         "#{ForemanOpennebula::Engine.root}/test/**/*.rb"]
      end
    rescue
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_opennebula'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_opennebula']

load 'tasks/jenkins.rake'
if Rake::Task.task_defined?(:'jenkins:unit')
  Rake::Task['jenkins:unit'].enhance ['test:foreman_opennebula', 'foreman_opennebula:rubocop']
end
