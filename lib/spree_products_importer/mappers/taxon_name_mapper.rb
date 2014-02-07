#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class TaxonNameMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Taxonomy
      #
      # Returns an Symbol
      def self.data
        :product
      end

      def self.make_ids_array value
        Mappers::BaseMapper.make_ids_array(value).map do |name|
          if Spree::Taxon.exists?({name: name})
            Spree::Taxon.find_by({name: name}).id
          else
            nil
          end
        end.compact
      end
    end
  end
end