#encoding: utf-8
require 'roo'
require 'httparty'

module SpreeProductsImporter

  class Handler

    # Receives a file and the get data from each file row
    def self.get_file_data(file)

      begin
        spreadsheet = open_spreadsheet(file)
      rescue RuntimeError => e
        return [false, e.message]
      end

      header        = spreadsheet.row(1)
      products_list = []
      api_error     = ""

      # Validates each row element
      (2..spreadsheet.last_row).each do |i|
        row            = Hash[[header, spreadsheet.row(i)].transpose]
        is_valid, data = validate_product_data row, i

        if is_valid
          products_list << data
        else
          return [false, data]
        end
      end

      # Creates each product with Spree API
      products_list.each do |product_data|
        # Create product (Add shipping_category_id and available_on attributes)
        product = Spree::Product.create product_data[:product].merge(shipping_category_id: 1, available_on: Time.now)
        # Set product categories(taxons)
        set_product_categories product, product_data[:values]
        # Set product origin
        set_product_origin product, product_data[:values]
        # Set product brand
        set_product_brand product, product_data[:values]
        # set_product_properties product, product_data[:properties]
      end

      return [true, "Products created successfully"]
    end

    # Receives a file and then returns a Roo object acording the file extension
    def self.open_spreadsheet(file)
      filename = Rails.env.test? ? File.basename(file) : file.original_filename

      case File.extname(filename)
      when '.csv' then Roo::CSV.new(file.path)
      when ".xls" then Roo::Excel.new(file.path, nil, :ignore)
      when ".xlsx" then Roo::Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{filename}"
      end
    end

    # Validate each file row according to required attributes
    def self.validate_product_data data, line_number
      required_attributes = ["sku", "name", "price"]
      optional_attributes = ["description", "sale_price", "ean_13", "technical_description"]

      validated_data = {
        product: {},
        values: {}
      }

      # Check for required attributes
      required_attributes.each do |attr|
        if data[attr].blank?
          return [false, "An error found at line #{line_number}: #{attr} is required"]
        else

          # When sku is numeric remove the decimal values
          if attr == "sku" and data[attr].is_a? Numeric
            attr_value = data[attr].to_i
          else
            attr_value = data[attr]
          end

          # Add key => value to normalized and validated hash
          validated_data[:product] = validated_data[:product].merge(attr.to_sym => attr_value)

          # Remove validate element
          data.delete(attr)
        end
      end

      # Check for optional attributes
      optional_attributes.each do |attr|
        # When sku is numeric remove the decimal values
        if attr == "ean_13" and data[attr].is_a? Numeric
          attr_value = data[attr].to_i
        else
          attr_value = data[attr]
        end

        # Add key => value to normalized and validated hash
        validated_data[:product] = validated_data[:product].merge(attr.to_sym => attr_value) unless attr_value.blank?

        # Remove validate element
        data.delete(attr)
      end

      validated_data[:values] = data

      [true, validated_data]
    end

    def self.set_product_properties product, properties
      # If exist remove taxons because they should not be saved as properties
      unless properties["taxons"].blank?
        if properties.count < 2
          properties = {}
        else
          properties = properties.delete("taxons")
        end
      end

      # Add each property to product
      properties.each do |(property_key, property_value)|
        product.set_property(property_key, property_value) unless property_value.blank?
      end
    end

    def self.set_product_categories product, values

      values.each do |key, value|
        # When column name starts with 'taxons' try add to the product taxons
        if key[0..5] == "taxons" and !value.blank?
          taxon = Spree::Taxon.find_by_name(value.strip)
          product.taxons << taxon if taxon.presence
        end
      end
    end

    def self.set_product_origin product, values

      values.each do |key, value|
        # When column name is 'origin'
        if key == 'origin' and !value.blank?
          taxon = Spree::Taxon.find_by_name(value.strip)
          product.taxons << taxon if taxon.presence
        end
      end
    end

    def self.set_product_brand product, values
      values.each do |key, value|
        # When column name is 'brand'
        if key == 'brand' and !value.blank?
          taxon = Spree::Taxon.find_by_name(value.strip)

          unless taxon.presence
            parent = Spree::Taxon.find_by_name("Marcas")
            data   = {name: value}
            data   = data.merge(parent_id: parent.id) unless parent.blank?
            taxon  = Spree::Taxon.create(data)
          end

          product.taxons << taxon unless product.taxons.include? taxon
        end
      end
    end

  end

end
