SpreeProductsImporter
=====================

Import tool for Spree Product.

Installation
------------

Add spree_products_importer to your Gemfile:

```ruby
gem 'spree_products_importer'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_products_importer:install
```

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_products_importer/factories'
```

Copyright (c) 2014 [Acid Labs](http://acid.cl), all rigths reserved.
