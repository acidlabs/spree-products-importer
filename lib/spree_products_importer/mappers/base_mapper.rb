#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class BaseMapper
      STRING_TYPE  = 'string'
      INTEGER_TYPE = 'integer'
      ARRAY_TYPE   = 'array'

      def self.splitter
        ','
      end

      def self.parse value, type
        case type
          when STRING_TYPE  then value.to_i.to_s
          when INTEGER_TYPE then value.to_i
          when ARRAY_TYPE   then make_ids_array(value)
          else return value
        end
      end

      def self.make_ids_array value
        value.class == Float ? [value.to_i.to_s] : value.split(splitter)
      end

      # Indicates the section where field is stored in the data Hash
      #
      # Returns an Symbol
      def self.data
        # TODO - quitar dependencia de esta funcion
        raise 'You must define this function and return the correct value, the available settings are: [:product, :variants, :taxons, :properties, :aditionals]'
      end
    end
  end
end