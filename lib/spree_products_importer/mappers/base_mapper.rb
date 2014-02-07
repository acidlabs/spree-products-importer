#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class BaseMapper
      STRING_TYPE  = 'string'
      INTEGER_TYPE = 'integer'
      ARRAY_TYPE   = 'integer'

      def splitter
        ','
      end

      def self.parse value, type
        case type
          when STRING_TYPE  then value.to_i.to_s
          when INTEGER_TYPE then value.to_i
          when ARRAY_TYPE   then value.to_i.to_s.split(splitter)
          else return value
        end
      end

      # Indicates the section where field is stored in the data Hash
      #
      # Returns an Symbol
      def self.data
        raise 'You must define this function and return the correct value, the available settings are: [:product, :variants, :taxons, :properties, :aditionals]'
      end
    end
  end
end