#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class VariantMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Product
      #
      # Returns an Symbol
      def self.data
        :variant
      end
    end
  end
end