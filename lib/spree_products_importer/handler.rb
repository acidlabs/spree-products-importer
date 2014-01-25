#encoding: utf-8
require 'roo'
require 'rest-client'

module SpreeProductsImporter

  class Handler

    @@api_url_base = "http://localhost:3000/api"
    @@api_token    = "26bc0e875720cfcae1aefb51b9f20a3ba96d86f8d307d96f"

    # Receives a file and the get data from each file row
    def self.get_file_data(file)
      spreadsheet   = open_spreadsheet(file)
      header        = spreadsheet.row(1)
      products_list = []
      api_error     = ""
      success       = true

      # Validates each row element
      (2..spreadsheet.last_row).each do |i|
        row            = Hash[[header, spreadsheet.row(i)].transpose]
        # TODO: Falta hacer el metodo validate_product_data
        is_valid, data = validate_product_data row

        if is_valid
          products_list << data
        else
          return data
        end
      end

      # Creates each product with Spree API
      products_list.each do |product|
        begin
          # Create a Product
          raise
          response = RestClient.post "#{@@api_url_base}/products?token=#{@@api_token}", {product: product}.to_json, {content_type: :json, accept: :json}
          # TODO: Add properties to recently created product

        rescue RestClient::BadRequest => e
          api_error = e
          success   = false
        end
      end

      return success ? "Products created successfully" : "API error #{e}"
    end
      
    # Receives a file and then returns a Roo object acording the file extension
    def self.open_spreadsheet(file)
      case File.extname(file.original_filename)
      when '.csv' then Roo::Csv.new(file.path, nil, :ignore)
      when '.xls' then Roo::Excel.new(file.path, nil, :ignore)
      when '.xlsx' then Roo::Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
      end
    end

    # Validate each file row according to required attributes
    def self.validate_product_data data
      required_attributes = ["sku", "name", "price"]
      validated_data = {}

      required_attributes.each do |attr|
        if data[attr].blank?
          return [false, "An error found at line #{i}: #{attr} is required"]
        else
          # Add key => value to normalized and validated hash
          validated_data = validated_data.merge(attr.to_sym => data[attr])
        end
      end

      #[true, validated_data]
      [true, validated_data.merge(:shipping_category_id => 1)]
    end

  end

end
