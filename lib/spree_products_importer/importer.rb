#encoding: utf-8

require 'roo'
require 'httparty'

module SpreeProductsImporter
  class Importer
    @spreadsheet = nil

    @currency = 'USD'

    @product_identifier = {name: :name, column: 'A', type: nil, mapper: Mappers::ProductMapper}

    @attributes = [
                    {required: true,  name: :name,   column: 'A', type: nil,                               mapper: Mappers::ProductMapper},
                    {required: true,  name: :price,  column: 'B', type: Mappers::BaseMapper::INTEGER_TYPE, mapper: Mappers::ProductMapper},
                    {required: true,  name: :sku,    column: 'C', type: Mappers::BaseMapper::STRING_TYPE,  mapper: Mappers::VariantMapper},
                    {required: true,  name: :taxons, column: 'D', type: Mappers::BaseMapper::ARRAY_TYPE,   mapper: Mappers::TaxonMapper  },
                  ]

    # Receives a file and the get data from each file row
    def self.get_file_data(file)
      begin
        open_spreadsheet(file)
      rescue RuntimeError => e
        return e.message
      end

      # Set the currency for Import
      set_import_currency

      # Validates each row element
      2.upto(@spreadsheet.last_row).each do |row_index|
        begin
          row = get_data(row_index)

          make_products   row
          make_variants   row
          make_taxons     row
          make_properties row
          make_aditionals row

        rescue RuntimeError => e
          raise "EN RuntimeError"

          return e.message
        rescue
          raise "EN Generic Error"

          return I18n.t(:products_cannot_be_created, scope: [:spree, :spree_products_importer, :messages])
        ensure
          # Restore the correct currency after Import
          restore_correct_currency
        end
      end

      return I18n.t(:products_created_successfully, scope: [:spree, :spree_products_importer, :messages])
    end

    # Defines the hash with default data and structure used to read the data in each row from excel
    # This allows easy customizations, overwriting this function
    #
    # Returns an Hash
    def self.default_hash
      {
        product: {},
        variant: {},
        taxons: [],
        properties: [],
        aditionals: []
      }
    end

    private
      # Set the currency for Import
      def self.set_import_currency
        # Store current currency
        current_currency = Spree::Config[:currency]

        # Sets the correct currency for import
        Spree::Config[:currency] = @currency
      end

      # Restore the correct currency after Import
      def self.restore_correct_currency
        # Store current currency
        current_currency = Spree::Config[:currency]

        # Sets the correct currency for import
        Spree::Config[:currency] = @currency
      end

      # Is responsible for creating the Product
      def self.make_products row
        if row[:product][:id].nil?
          product = Spree::Product.create! row[:product]

          # Store the Product :id in the row Hash data
          row[:product] = {id: product.id}
        else
          # Product already exists
        end
      end

      # Is responsible for creating the Variant
      def self.make_variants row
        if row[:product][:id].nil?
          raise [false, I18n.t(:product_not_found, scope: [:spree, :spree_products_importer, :messages])]
        else
          variant = Spree::Variant.create! row[:variant].merge({product_id: row[:product][:id]})

          # Store the Variant :id in the row Hash data
          row[:variant][:id] = variant.id
        end
      end

      # Is responsible for creating the Taxon's
      def self.make_taxons row
      end

      # Is responsible for creating the Properties imports
      def self.make_properties row
      end

      # Is responsible for creating the Aditionals imports
      def self.make_aditionals row
      end

      # TODO - Import Variants
      # TODO - Import Taxons
      # TODO - Import Properties
      # TODO - Import Aditionals
      def self.get_data row_index
        data = default_hash

        # Check if the product exists
        unformat_product_identifier = @spreadsheet.cell(row_index, @product_identifier[:column])
        product_identifier          = @product_identifier[:mapper].parse unformat_product_identifier, @product_identifier[:type]
        if Spree::Product.exists?({@product_identifier[:name] => product_identifier})
          data[:product]      = {}
          data[:product][:id] = Spree::Product.find_by({@product_identifier[:name] => product_identifier}).id
        end

        @attributes.each do |attribute|
          value = attribute[:mapper].parse @spreadsheet.cell(row_index, attribute[:column]), attribute[:type]

          # TODO - Required data may be omitted if the product already exists
          raise [false, I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], row: row_index, attribute: attribute[:name])] if value.nil? and attribute[:required]

          if attribute[:mapper].data == :product
            # If I have the ID of the product do nothing because it is not going to edit the product
            next if data[:product][:id]

            if attribute[:type] == Mappers::BaseMapper::ARRAY_TYPE
              data[:product][attribute[:name]] = [] if data[:product][attribute[:name]].nil?

              data[:product][attribute[:name]] += value
            else
              data[:product][attribute[:name]] = value
            end

          elsif attribute[:mapper].data == :variant
            if attribute[:type] == Mappers::BaseMapper::ARRAY_TYPE
              data[:variant][attribute[:name]] = [] if data[:variant][attribute[:name]].nil?

              data[:variant][attribute[:name]] += value
            else
              data[:variant][attribute[:name]] = value
            end

          # TODO
          # elsif attribute[:mapper].data == :taxons
          #  taxon[attribute[:name]] = value
          #
          # TODO
          # elsif attribute[:mapper].data == :properties
          #  property[attribute[:name]] = value
          #
          # TODO
          # elsif attribute[:mapper].data == :aditionals
          #  aditional[attribute[:name]] = value
          end
        end

        data
      end

      # Receives a file instance and then returns a Roo object acording the file extension
      #
      # @params:
      #   file     File   -  a file intance with data to load
      #
      # Returns a Roo instance acording the file extension.
      def self.open_spreadsheet(file)
        filename = Rails.env.test? ? File.basename(file) : file.original_filename

        case File.extname(filename)
          # when '.csv'  then @spreadsheet = Roo::CSV.new(file.path)
          # when '.xls'  then @spreadsheet = Roo::Excel.new(file.path, nil, :ignore)
          when '.xlsx' then @spreadsheet = Roo::Excelx.new(file.path, nil, :ignore)
          else raise [false, I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], filename: filename)]
        end

        @spreadsheet.default_sheet = @spreadsheet.sheets.first
      end
  end
end