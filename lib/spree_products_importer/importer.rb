#encoding: utf-8
require 'roo'
require 'httparty'

module SpreeProductsImporter

  class Importer
    @spreadsheet = nil

    @product_identifier = {name: :name, column: 'A', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper}

    @attributes = [
                    {required: true,  name: :name,       column: 'A', type: nil,                               mapper: Mappers::ProductMapper },
                    {required: true,  name: :price,      column: 'B', type: Mappers::BaseMapper::INTEGER_TYPE, mapper: Mappers::ProductMapper },
                    {required: true,  name: :sku,        column: 'C', type: Mappers::BaseMapper::STRING_TYPE,  mapper: Mappers::VariantMapper },
                    {required: true,  name: :taxonomies, column: 'D', type: Mappers::BaseMapper::ARRAY_TYPE,   mapper: Mappers::TaxonomyMapper},
                  ]

    # Receives a file and the get data from each file row
    def self.get_file_data(file)
      begin
        open_spreadsheet(file)
      rescue RuntimeError => e
        return e.message
      end

      rows = []

      # Validates each row element
      2.upto(@spreadsheet.last_row).each do |row_index|
        # begin
          row = get_data(row_index)
        # rescue RuntimeError => e
        #   return e.message
        # end

        rows << row
      end

      # Create product from :data
      raise "Crear los productos"

      return "Products created successfully"
    end

    private
      # TODO - Import Variants
      # TODO - Import Taxonomies
      # TODO - Import Properties
      def self.get_data row_index
        data = {product: {}, variants: [], taxonomies: [], properties: []}

        # Reviso si el producto existe
        unformat_product_identifier = @spreadsheet.cell(row_index, @product_identifier[:column])
        product_identifier = @product_identifier[:mapper].parse unformat_product_identifier, @product_identifier[:type]
        if Spree::Product.exists?({@product_identifier[:name] => product_identifier})
          data[:product][:id] = Spree::Product.find_by({@product_identifier[:name] => product_identifier}).id
        end

        variant = nil

        @attributes.each do |attribute|
          value = attribute[:mapper].parse @spreadsheet.cell(row_index, attribute[:column]), attribute[:type]

          raise "An error found at line #{row_index}, :#{attribute[:name]} is required" if value.nil? and attribute[:required]

          if attribute[:mapper].data == :product or (attribute[:mapper].data == :variants and is_product?(@product_identifier[:column], unformat_product_identifier))
            # Si tengo el ID del producto no hago nada proque no se va a editar el producto
            next if data[:product][:id]

            data[:product][attribute[:name]] = value

          elsif attribute[:mapper].data == :variants
            variant = {} if variant.nil?
            variant[attribute[:name]] = value

          # TODO
          # elsif attribute[:mapper].data == :taxonomies
          #  taxonomy[attribute[:name]] = value
          #
          # TODO
          # elsif attribute[:mapper].data == :properties
          #  property[attribute[:name]] = value
          end
        end

        data[:variants] << variant unless variant.nil?

        data
      end

      # Receives a file instnace and then returns a Roo object acording the file extension
      #
      # @params:
      #   file     File   -  a file intance with data to load
      #
      # Returns a Roo instance acording the file extension.
      def self.open_spreadsheet(file)
        filename = Rails.env.test? ? File.basename(file) : file.original_filename

        case File.extname(filename)
          when '.csv'  then @spreadsheet = Roo::CSV.new(file.path)
          when '.xls'  then @spreadsheet = Roo::Excel.new(file.path, nil, :ignore)
          when '.xlsx' then @spreadsheet = Roo::Excelx.new(file.path, nil, :ignore)
          else raise "Unknown file type: #{filename}"
        end

        @spreadsheet.default_sheet = @spreadsheet.sheets.first
      end

      # Checks if the Record to be inserted corresponds to a Product or a Variant
      #
      # @params:
      #   column            String   -  the column that allows discrimination between products and variants
      #   identifier_value           -  the value to consult, value should be as its returned by cell(a, b) function
      #
      # Returns a Boolean.
      def self.is_variant? column, identifier_value
        @spreadsheet.column(column).count(identifier_value) > 1
      end
      def self.is_product? column, identifier_value
        !is_variant?(column, identifier_value)
      end
  end
end