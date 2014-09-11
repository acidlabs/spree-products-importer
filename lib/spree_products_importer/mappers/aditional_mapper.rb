#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class AditionalMapper < SpreeProductsImporter::Mappers::BaseMapper
      def load spreadsheet, row, data
        cell = spreadsheet.cell(row, @col)

        unless cell.nil?
          data[:aditionals][@attribute] = parse(cell)
        end
      end
    end
  end
end