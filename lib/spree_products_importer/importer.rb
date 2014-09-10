#encoding: utf-8

require 'roo'
require 'httparty'

module SpreeProductsImporter
  class Importer
    def initialize filename, filepath
      @filename = filename
      @filepath  = filepath

      # Parsed Data
      @spreadsheet = nil

      # # TODO - remover dependencia de mapper
      # @product_identifier = {name: :sky, column: 'A', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper}

      # @attributes = [
      #                 {required: true, name: :sku,         column: 'A', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper},
      #                 {required: true, name: :name,        column: 'B', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper},
      #                 {required: true, name: :description, column: 'C', type: Mappers::BaseMapper::STRING_TYPE, mapper: Mappers::ProductMapper}
      #               ]
      @mappers = []
      @mappers << Mappers::ProductMapper.new('A', :sku)
      @mappers << Mappers::ProductMapper.new('B', :name)
      @mappers << Mappers::ProductMapper.new('C', :description)
    end

    # Load a file and the get data from each file row
    def load_products
      puts I18n.t(:reading, scope: [:spree, :spree_products_importer, :logs], filename: @filename) if Spree::Config.verbose

      start = Time.now
      begin
        open_spreadsheet
      rescue RuntimeError => e
        return e.message
      end
      puts I18n.t(:loading_file, scope: [:spree, :spree_products_importer, :logs], filename: @filename, time: Time.now - start) if Spree::Config.verbose


      start = Time.now

      failed_rows = []

      # Load each row element
      2.upto(@spreadsheet.last_row).each do |row_index|
        Spree::Product.transaction do
          begin
            row = get_data(row_index)
            data = row.deep_dup

            # make_products   row
            # make_variants   row
            # make_taxons     row
            # make_properties row
            # make_images     row
            # make_aditionals row

            if Spree::Config.verbose and row_index % Spree::Config[:log_progress_every] == 0
              puts I18n.t(:progress, scope: [:spree, :spree_products_importer, :logs], filename: @filename, time: Time.now - start, row: row_index, rows: @spreadsheet.last_row, data: data)
              start = Time.now
            end

          rescue RuntimeError => e
            puts I18n.t(:error, scope: [:spree, :spree_products_importer, :logs], filename: @filename, row: row_index, rows: @spreadsheet.last_row, data: data.inspect, message: e.message) if Spree::Config.verbose

            failed_rows << {row_index: row_index, message: e.message, data: data}

            raise ActiveRecord::Rollback
          rescue => e
            puts I18n.t(:error, scope: [:spree, :spree_products_importer, :logs], filename: @filename, row: row_index, rows: @spreadsheet.last_row, data: data.inspect, message: e.message) if Spree::Config.verbose

            failed_rows << {row_index: row_index, message: e.message, data: data}

            raise ActiveRecord::Rollback
          ensure

          end
        end
      end

      puts I18n.t(:done, scope: [:spree, :spree_products_importer, :logs], filename: @filename) if Spree::Config.verbose

      if failed_rows.empty?
        NotificationMailer.successfully(@filename).deliver
      else
        NotificationMailer.error(@filename, failed_rows).deliver
      end
    end

    # Defines the hash with default data and structure used to read the data in each row from excel
    # This allows easy customizations, overwriting this function
    #
    # Returns an Hash
    def default_hash
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
      # Receives a file instance and then returns a Roo object acording the file extension
      #
      # @params:
      #   file     File   -  a file intance with data to load
      #
      # Returns a Roo instance acording the file extension.
      def open_spreadsheet
        case File.extname(@filename)
          when '.csv'  then @spreadsheet = Roo::CSV.new(@filepath)
          # when '.xls'  then @spreadsheet = Roo::Excel.new(filepath, nil, :ignore)
          # when '.xlsx' then @spreadsheet = Roo::Excelx.new(filepath, nil, :ignore)
          else raise "#{__FILE__}:#{__LINE__} #{I18n.t(:unknown_file_type, scope: [:spree, :spree_products_importer, :messages], filename: @filename)}"
        end

        @spreadsheet.default_sheet = @spreadsheet.sheets.first
      end

      # Find and returns a Product or raise an error
      def find_product row
        # Reviso que este seteado el :id del Product
        raise "#{__FILE__}:#{__LINE__} #{I18n.t(:product_not_found, scope: [:spree, :spree_products_importer, :messages])}" if row[:product][:id].nil?

        # Find Product by :id
        Spree::Product.find(row[:product][:id])
      end

      # Is responsible for creating the Product
      def make_products row
        if row[:product][:id].nil?
          row[:product][:taxon_ids].uniq! if row[:product][:taxon_ids]

          product = Spree::Product.create! row[:product]

          # Store the Product :id in the row Hash data
          row[:product] = {id: product.id}
        else
          # Product already exists
          # TODO - Ver si se van a actualizar los datos del Product
        end
      end

      # Is responsible for creating the Variant
      def make_variants row
        variant = Spree::Variant.find_by product_id: row[:product][:id], sku: row[:variant][:sku]
        if variant.nil?
          variant = Spree::Variant.create! row[:variant].merge({product_id: row[:product][:id]})
        end
        # Store the Variant :id in the row Hash data
        row[:variant][:id] = variant.id
      end

      # Is responsible for creating the Taxon's
      def make_taxons row
        # TODO - Implementar
      end

      # Is responsible for creating the ProductProperties imports
      def make_properties row
        row[:properties].each do |property|
          property.keys.each do |property_name|
            # Revisa si ya existe la Spree::ProductProperty, en cuyo caso se descarta la carga
            next if Spree::ProductProperty.joins(:property).where(value: property[property_name], product_id: row[:product][:id]).where(spree_properties: {name: property_name.to_s}).any?

            Spree::ProductProperty.create! value: property[property_name], product_id: row[:product][:id], property_name: property_name.to_s
          end
        end
      end

      # Is responsible for creating the Images
      def make_images row
        row[:images].each do |name|

          extname       = File.extname(name)
          name_upcase   = name.gsub(extname, extname.upcase)
          name_downcase = name.gsub(extname, extname.downcase)

          original_path = Spree::Config[:images_importer_files_path] + name
          upcase_path   = Spree::Config[:images_importer_files_path] + name_upcase
          downcase_path = Spree::Config[:images_importer_files_path] + name_downcase

          # Revisa si ya existe la Imagen, en cuyo caso se descarta la carga
          next if Spree::Image.where(viewable_type: Spree::Variant.to_s, viewable_id: row[:variant][:id], attachment_file_name: [name, name_upcase, name_downcase]).any?

          if File.exists?(Rails.root + original_path)
            file = File.open(Rails.root + original_path)

            image = Spree::Image.new
            image.viewable_type   = Spree::Variant.to_s
            image.viewable_id   = row[:variant][:id]
            image.attachment = file
            image.type       = 'Spree::Image'
            image.alt        = ''

            image.save!
          elsif File.exists?(Rails.root + upcase_path)
            file = File.open(Rails.root + upcase_path)

            image = Spree::Image.new
            image.viewable_type   = Spree::Variant.to_s
            image.viewable_id   = row[:variant][:id]
            image.attachment = file
            image.type       = 'Spree::Image'
            image.alt        = ''

            image.save!
          elsif File.exists?(Rails.root + downcase_path)
            file = File.open(Rails.root + downcase_path)

            image = Spree::Image.new
            image.viewable_type   = Spree::Variant.to_s
            image.viewable_id   = row[:variant][:id]
            image.attachment = file
            image.type       = 'Spree::Image'
            image.alt        = ''

            image.save!
          else
            raise "#{__FILE__}:#{__LINE__} #{I18n.t(:image_not_found, scope: [:spree, :spree_products_importer, :messages], name: name)}"
          end
        end
      end

      # Is responsible for creating the Aditionals imports
      def make_aditionals row
        # Overrides this function to add aditionals or customs imports
      end

      # # TODO - Import Properties
      # def get_data row_index
      #   data = default_hash.deep_dup

      #   @attributes.each do |attribute|
      #     column      = attribute[:column]
      #     fieldname   = attribute[:name]
      #     mapper      = attribute[:mapper]
      #     required    = attribute[:required]
      #     type_parser = attribute[:type]
      #     section     = mapper.data

      #     cell = @spreadsheet.cell(row_index, column)

      #     # TODO - Required data may be omitted if the product already exists
      #     raise "#{__FILE__}:#{__LINE__} #{I18n.t(:an_error_found, scope: [:spree, :spree_products_importer, :messages], row: row_index, attribute: fieldname)}" if cell.nil? and required

      #     next if cell.nil?
      #     value_or_values = mapper.parse cell, type_parser

      #     # If I have the ID of the product do nothing because it is not going to edit the product
      #     next if data[:product][:id] if section == :product

      #     if section == :properties
      #       colname = @spreadsheet.cell(1, column)
      #       value_or_values.each do |value|
      #         data[section] << {colname => value}
      #       end

      #     elsif [:images, :taxons].include? section
      #       if value_or_values.class == Array
      #         data[section] += value_or_values
      #       else
      #         data[section] << value_or_values
      #       end

      #     else # :product, :variant, :aditionals
      #       if type_parser == Mappers::BaseMapper::ARRAY_TYPE
      #         data[section][fieldname] = [] if data[section][fieldname].nil?

      #         data[section][fieldname] += value_or_values
      #       else
      #         data[section][fieldname] = value_or_values
      #       end
      #     end
      #   end

      #   data
      # end
      def get_data row_index
        data = default_hash.deep_dup

        @mappers.each do |mapper|
          mapper.parse @spreadsheet, row_index, data
        end

        return data
      end
  end
end