#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class BaseMapper
      def initialize col, attribute
        @col = col
        @attribute = attribute
      end

      def parse cell
        return cell
      end
    end
  end
end
