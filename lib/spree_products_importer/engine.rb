module SpreeProductsImporter
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_products_importer'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "spree.importer.preferences", :before => :load_config_initializers do |app|
      Spree::AppConfiguration.class_eval do
        preference :importer, :string, :default => SpreeProductsImporter::Handler.to_s
        preference :import_currency, :string, :default => 'USD'
        preference :images_importer_files_path, :string, :default => 'public/importer/'
        preference :importer_from, :string, :default => 'notification@importer.com'
        preference :importer_to,   :string, :default => 'notification@importer.com'
      end
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), '../../app/workers/*_worker.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
