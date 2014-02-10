#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class PropertyMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Product
      #
      # Returns an Symbol
      def self.data
        :properties
      end

      def self.splitter
        '-/-'
      end

      def self.make_ids_array value
        value.split(splitter)
      end
    end
  end
end