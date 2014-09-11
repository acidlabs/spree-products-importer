#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class BaseMapper
      def initialize col, attribute, formater=nil
        @col       = col
        @attribute = attribute
        @formater  = formater
      end

      def parse cell
        if @formater
          return @formater.parse(cell)
        else
          return cell
        end
      end
    end
  end
end
