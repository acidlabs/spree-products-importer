# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_products_importer'
  s.version     = '2.0.0'
  s.summary     = 'Import tool for Spree Product'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Vladimir Suárez'
  s.email     = 'vladimir@acid.cl'
  s.homepage  = 'https://github.com/acidlabs'

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 2.0.0'
  s.add_dependency 'roo'

  s.add_development_dependency 'capybara', '~> 2.1'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.2'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.13'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'

  # Background Process
  s.add_runtime_dependency 'sidekiq'
  # s.add_development_dependency 'sidekiq'
  s.add_runtime_dependency 'sinatra'#, :require=> false
  # s.add_development_dependency 'sinatra'#, :require=> false
end
