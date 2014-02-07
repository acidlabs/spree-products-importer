#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class TaxonoMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Taxonomy
      #
      # Returns an Symbol
      def self.data
        :taxonomies
      end
    end
  end
end