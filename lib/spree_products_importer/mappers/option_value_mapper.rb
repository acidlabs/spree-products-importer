#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class OptionValueMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Product
      #
      # Returns an Symbol
      def self.data
        :variant
      end

      def self.make_ids_array value
        Mappers::BaseMapper.make_ids_array(value).map do |name|
          Spree::OptionValue.find_by({name: name}).id
        end
      end
    end
  end
end