#encoding: utf-8
require 'roo'
require 'httparty'

module SpreeProductsImporter

  class Importer
    @spreadsheet = nil

    @currency = 'USD'

    @product_identifier = {name: :name, column: 'A', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper}

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

      # Validates each row element
      2.upto(@spreadsheet.last_row).each do |row_index|
        begin
          row = get_data(row_index)
        rescue RuntimeError => e
          return e.message
        end

        make_products   row
        make_variants   row
        make_taxonomies row
        make_properties row
        make_aditionals row
      end

      return I18n.t(:products_created_successfully, scope: [:spree, :spree_products_importer, :messages])
    end

    def self.default_hash
      {product: {}, variant: {}, taxons: [], properties: []}
    end

    private
      # Is responsible for creating the Product
      def self.make_products row
        if row[:product][:id].nil?
          # Store current currency
          current_currency = Spree::Config[:currency]

          # Sets the correct currency for import
          Spree::Config[:currency] = @currency

          default_shipping_category = Spree::ShippingCategory.find_by_name!("Default")
          product = Spree::Product.create! row[:product]

          # Restore the correct currency
          Spree::Config[:currency] = current_currency

          # Store the Product :id in the row Hash data
          row[:product] = {id: product.id}
        else
          # Product already exists
        end
      end

      # Is responsible for creating the Variant
      def self.make_variants row
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

        # Reviso si el producto existe
        unformat_product_identifier = @spreadsheet.cell(row_index, @product_identifier[:column])
        product_identifier          = @product_identifier[:mapper].parse unformat_product_identifier, @product_identifier[:type]
        if Spree::Product.exists?({@product_identifier[:name] => product_identifier})
          data[:product]      = {}
          data[:product][:id] = Spree::Product.find_by({@product_identifier[:name] => product_identifier}).id
        end

        @attributes.each do |attribute|
          value = attribute[:mapper].parse @spreadsheet.cell(row_index, attribute[:column]), attribute[:type]

          # TODO - se pueden omitir datos obligatorios si el producto ya existe
          raise [false, I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], row: row_index, attribute: attribute[:name])] if value.nil? and attribute[:required]

          if attribute[:mapper].data == :product
            # Si tengo el ID del producto no hago nada proque no se va a editar el producto
            next if data[:product][:id]

            data[:product][attribute[:name]] = value

          elsif attribute[:mapper].data == :variant
            data[:variant][attribute[:name]] = value

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
          else raise [false, I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], filename: filename)]
        end

        @spreadsheet.default_sheet = @spreadsheet.sheets.first
      end
  end
end