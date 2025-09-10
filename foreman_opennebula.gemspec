require File.expand_path('lib/foreman_opennebula/version', __dir__)

Gem::Specification.new do |spec|
  spec.name        = 'foreman_opennebula'
  spec.version     = ForemanOpennebula::VERSION
  spec.authors     = ['Vitaly Pyslar']
  spec.email       = ['vpyslar@ivi.ru']

  spec.summary     = 'Foreman OpenNebula plugin'
  spec.description = 'Provision and manage OpenNebula VMs from Foreman'
  spec.homepage    = 'https://github.com/theforeman/foreman_opennebula'
  spec.license     = 'GPL-3.0'
  spec.metadata    = { 'is_foreman_plugin' => 'true' }

  spec.required_ruby_version = '>= 2.7'

  spec.files = Dir['{app,lib,db,config,locale,webpack}/**/*'] + ['LICENSE', 'Rakefile', 'README.md', 'package.json']
  spec.test_files = Dir['test/**/*']

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rdoc', '~> 6.4'
  spec.add_development_dependency 'theforeman-rubocop', '~> 0.1.2'

  spec.add_runtime_dependency 'fog-opennebula', '~> 0.0'
  spec.add_dependency 'deface'
end
