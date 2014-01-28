# encoding: utf-8
require 'spec_helper'

describe "SpreeProductsImporter::Handler" do

  describe '#validate_product_data' do

    let!(:valid_data) {{ "name" => 'Product 1', "price" => 80000, "sku" => "ABC1234", "property1" => "A", "property2" => "B"}}
    let!(:valid_data_without_properties) {{ "name" => 'Product 2', "price" => 80000, "sku" => "ABC1234" }}
    let!(:invalid_data) {{ "name" => nil, "price" => 80000, "sku" => "ABC1234" }}
    let!(:invalid_data_2) {{ "name" => "Product 3", "sku" => "ABC1234" }}
    
    context "with valid arguments" do

      it "returns true as first list element" do
        result = SpreeProductsImporter::Handler.validate_product_data(valid_data, 2)

        result.first.should be_true
      end

      it "returns validated product data in a hash" do
        result = SpreeProductsImporter::Handler.validate_product_data(valid_data_without_properties, 2)

        result.last[:product][:name].should eq "Product 2"
        result.last[:product][:price].should eq 80000
        result.last[:product][:sku].should eq "ABC1234"
      end

      it "returns product properties in a hash" do
        result = SpreeProductsImporter::Handler.validate_product_data(valid_data, 2)

        result.last[:properties]["property1"].should eq "A"
        result.last[:properties]["property2"].should eq "B"
      end

      context "with valid arguments without product properties" do
        it "returns a empty properties hash" do
          result = SpreeProductsImporter::Handler.validate_product_data(valid_data_without_properties, 2)

          result.last[:properties].should be_empty
        end
      end

    end

    context "with invalid arguments" do

      it "returns false as first list element" do
        result = SpreeProductsImporter::Handler.validate_product_data(invalid_data, 2)

        result.first.should be_false
      end

      it "returns a custom message as second list element" do
        result = SpreeProductsImporter::Handler.validate_product_data(invalid_data, 2)

        result.last.should eq "An error found at line 2: name is required"
      end

      it "returns a custom message as second list element when a specified key is not present" do
        result = SpreeProductsImporter::Handler.validate_product_data(invalid_data_2, 2)

        result.last.should eq "An error found at line 2: price is required"
      end

    end

  end

  describe "#open_spread_sheet" do

    context "with a valid file" do
      it "returns a instance of Roo::Excelx" do
        data = SpreeProductsImporter::Handler.open_spreadsheet File.open("spec/support/products.xlsx", "r")
        
        data.should be_an_instance_of Roo::Excelx
      end

      it "returns a instance of Roo::Excel" do
        data = SpreeProductsImporter::Handler.open_spreadsheet File.open("spec/support/products.xls", "r")
        
        data.should be_an_instance_of Roo::Excel
      end

      it "returns a instance of Roo::CSV" do
        data = SpreeProductsImporter::Handler.open_spreadsheet File.open("spec/support/products.csv", "r")
        
        data.should be_an_instance_of Roo::CSV
      end
    end

    context "with an invalid file" do
      it "raises an exception" do
        lambda { SpreeProductsImporter::Handler.open_spreadsheet File.open("spec/support/products.txt", "r") }.should raise_error
      end
    end

  end

end