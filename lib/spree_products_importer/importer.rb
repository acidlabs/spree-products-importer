#encoding: utf-8

require 'roo'
require 'httparty'

module SpreeProductsImporter
  class Importer
    @spreadsheet = nil

    @current_currency = nil

    # TODO - remover dependencia de mapper
    @product_identifier = {name: :name, column: 'A', type: nil, mapper: Mappers::ProductMapper}

    @attributes = [
                    {required: true, name: :name,   column: 'A', type: nil,                               mapper: Mappers::ProductMapper},
                    {required: true, name: :price,  column: 'B', type: Mappers::BaseMapper::INTEGER_TYPE, mapper: Mappers::ProductMapper},
                    {required: true, name: :sku,    column: 'C', type: Mappers::BaseMapper::STRING_TYPE,  mapper: Mappers::VariantMapper},
                    {required: true, name: :taxons, column: 'D', type: Mappers::BaseMapper::ARRAY_TYPE,   mapper: Mappers::TaxonMapper  },
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
        # begin
          row = get_data(row_index)

          make_products   row
          make_variants   row
          make_taxons     row
          make_properties row
          make_images     row
          make_aditionals row

        # rescue RuntimeError => e
        #   return e.message
        # rescue => e
        #   return e.message
        # ensure
        #   # Restore the correct currency after Import
        #   restore_correct_currency
        # end
      end

      return I18n.t(:products_created_successfully, scope: [:spree, :spree_products_importer, :messages])
    end

    # Defines the hash with default data and structure used to read the data in each row from excel
    # This allows easy customizations, overwriting this function
    #
    # Returns an Hash
    def self.default_hash
      {
        product: {},      # {attribute1: VALUE_OR_VALUES, attribute2: VALUE_OR_VALUES, ...}
        variant: {},      # {attribute1: VALUE_OR_VALUES, attribute2: VALUE_OR_VALUES, ...}
        taxons: [],       # [taxon1, taxon2, ......]
        properties: [],   # [{property_name1: PROPERTY_VALUE}, {property_name2: PROPERTY_VALUE}, ....]
        images: [],       # [file_name1, file_name2, ......]
        aditionals: {}    # {aditional1: ADITIONAL_VALUE_OR_VALUES, aditional2: ADITIONAL_VALUE_OR_VALUES, ....}
      }
    end

    private
      # Set the currency for Import
      def self.set_import_currency
        # Store current currency
        @current_currency = Spree::Config[:currency]

        # Sets the correct currency for import
        Spree::Config[:currency] = Spree::Config[:import_currency]
      end

      # Restore the correct currency after Import
      def self.restore_correct_currency
        # Sets the correct currency for import
        Spree::Config[:currency] = @current_currency
      end

      # Find and returns a Product or raise an error
      def self.find_product row
        # Reviso que este seteado el :id del Product
        raise [false, I18n.t(:product_not_found, scope: [:spree, :spree_products_importer, :messages])] if row[:product][:id].nil?

        # Find Product by :id
        Spree::Product.find(row[:product][:id])
      end

      # Is responsible for creating the Product
      def self.make_products row
        if row[:product][:id].nil?
          product = Spree::Product.create! row[:product]

          # Store the Product :id in the row Hash data
          row[:product] = {id: product.id}
        else
          # Product already exists
          # TODO - Ver si se van a actualizar los datos del Product
        end
      end

      # Is responsible for creating the Variant
      def self.make_variants row
        product = find_product row

        if product.variants.where(sku: row[:variant][:sku]).any?
          variant = product.variants.where(sku: row[:variant][:sku]).last

          # TODO - Ver si se van a actualizar los datos de la Variant
        else
          variant = Spree::Variant.create! row[:variant].merge({product_id: row[:product][:id]})
        end

        # Store the Variant :id in the row Hash data
        row[:variant][:id] = variant.id
      end

      # Is responsible for creating the Taxon's
      def self.make_taxons row
        # TODO - Implementar
      end

      # Is responsible for creating the ProductProperties imports
      def self.make_properties row
        product = find_product row

        row[:properties].each do |property|
          property.keys.each do |property_name|
            # TODO - Revisar si ya existe la <PropertyName - PropertyValue>
            Spree::ProductProperty.create! value: property[property_name.to_sym], product_id: product.id, property_name: property_name.to_s
          end
        end
      end

      # Is responsible for creating the Images
      def self.make_images row
        product = find_product row
        master  = product.master

        row[:images].each do |name|
          # TODO - Revisar si ya existe la Image

          path = Spree::Config[:images_importer_files_path] + name
          file = File.open(Rails.root + path)

          image = Spree::Image.new
          image.viewable   = master
          image.attachment = file
          image.type       = 'Spree::Image'
          image.alt        = ''

          image.save!
        end
      end

      # Is responsible for creating the Aditionals imports
      def self.make_aditionals row
        # Overrides this function to add aditionals or customs imports
      end

      # TODO - Import Properties
      def self.get_data row_index
        parsed_data = default_hash

        # Check if the product exists
        unformat_product_identifier = @spreadsheet.cell(row_index, @product_identifier[:column])
        product_identifier          = @product_identifier[:mapper].parse unformat_product_identifier, @product_identifier[:type]
        if Spree::Product.exists?({@product_identifier[:name] => product_identifier})
          parsed_data[:product]      = {}
          parsed_data[:product][:id] = Spree::Product.find_by({@product_identifier[:name] => product_identifier}).id
        end

        @attributes.each do |attribute|
          column      = attribute[:column]
          fieldname   = attribute[:name]
          mapper      = attribute[:mapper]
          required    = attribute[:required]
          type_parser = attribute[:type]
          section     = mapper.data


          cell = @spreadsheet.cell(row_index, column)

          # TODO - Required data may be omitted if the product already exists
          raise [false, I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], row: row_index, attribute: fieldname)] if cell.nil? and required

          next if cell.nil?
          value_or_values = mapper.parse cell, type_parser

          # If I have the ID of the product do nothing because it is not going to edit the product
          next if parsed_data[:product][:id] if section == :product

          if [:images, :taxons, :properties].include? section
            if value_or_values.class == Array
              parsed_data[section] += value_or_values
            else
              parsed_data[section] << value_or_values
            end
          else
            if type_parser == Mappers::BaseMapper::ARRAY_TYPE
              parsed_data[section][fieldname] = [] if parsed_data[section][fieldname].nil?

              parsed_data[section][fieldname] += value_or_values
            else
              parsed_data[section][fieldname] = value_or_values
            end
          end
        end

        parsed_data
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