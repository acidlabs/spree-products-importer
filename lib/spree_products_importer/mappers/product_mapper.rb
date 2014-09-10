#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class ProductMapper
      def initialize col, attribute
        @col = col
        @attribute = attribute
      end


      def parse spreadsheet, row, data
        cell = spreadsheet.cell(row, @col)

        unless cell.nil?
          data[:product][@attribute] = cell
        end
      end
    end
  end
end