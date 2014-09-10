#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class ProductMapper < SpreeProductsImporter::Mappers::BaseMapper
      def load spreadsheet, row, data
        cell = spreadsheet.cell(row, @col)

        unless cell.nil?
          data[:product][@attribute] = parse(cell)
        end
      end
    end
  end
end
