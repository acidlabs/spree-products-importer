# encoding: utf-8

require 'rubygems'
require 'sidekiq'

module SpreeProductsImporter
  class ImporterWorker
    include Sidekiq::Worker

    sidekiq_options retry: false

    def perform(filename, filepath)
      importer = SpreeProductsImporter::Importer.new filename, filepath

      importer.load_products
    end
  end
end
