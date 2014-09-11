#encoding: utf-8
module SpreeProductsImporter
  class ProductIdentifier
    def initialize col, attribute
      @col = col
      @attribute = attribute
    end

    def exists? spreadsheet, row
      cell = spreadsheet.cell(row, @col)

      if cell.nil?
        return false
      else
        return Spree::Product.exists?(@attribute => cell)
      end
    end
  end
end
