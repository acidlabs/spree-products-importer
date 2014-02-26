# encoding: utf-8

require 'rubygems'
require 'sidekiq'

module SpreeProductsImporter
  class ProductsWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(filename, filepath)
      SpreeProductsImporter::Importer.load_products(filename, filepath)
    end
  end
end