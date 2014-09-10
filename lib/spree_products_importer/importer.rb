#encoding: utf-8

require 'roo'
require 'httparty'

module SpreeProductsImporter
  class Importer
    def initialize filename, filepath
      @filename = filename
      @filepath  = filepath

      @spreadsheet = nil

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
            # ToDo - Revisar que no exista, de lo contrario saltarse la fila
            data = default_hash.deep_dup

            @mappers.each do |mapper|
              mapper.parse @spreadsheet, row_index, data
            end

            # make_products   row

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

      # Is responsible for creating the Product
      def make_products row
        product = Spree::Product.create! row[:product]

        # Store the Product :id in the row Hash data
        row[:product][:id] = product.id
      end
  end
end