#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class TaxonMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Taxonomy
      #
      # Returns an Symbol
      def self.data
        :product
      end

      def self.make_ids_array value
        Mappers::BaseMapper.make_ids_array(value).map do |code|
          if Spree::Taxon.exists?({code: code})
            Spree::Taxon.find_by({code: code}).id
          else
            nil
          end
        end.compact
      end
    end
  end
end