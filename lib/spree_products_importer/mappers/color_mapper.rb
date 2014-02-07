#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class ColorMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Product
      #
      # Returns an Symbol
      def self.data
        :variant
      end

      def self.make_ids_array value
        Mappers::BaseMapper.make_ids_array(value).map do |ax_id|
          Spree::Color.find_by({ax_id: ax_id}).id
        end
      end
    end
  end
end