#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class OptionValueMapper < SpreeProductsImporter::Mappers::BaseMapper
      def load spreadsheet, row, data
        cell = spreadsheet.cell(row, @col)

        unless cell.nil?
          data[:option_values][@attribute] = [] unless data[:option_values][@attribute]
          data[:option_values][@attribute] += parse(cell)
        end
      end
    end
  end
end