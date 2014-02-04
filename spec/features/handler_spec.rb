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

  describe "#get_file_data" do

    context "with a valid file" do
      let!(:xlsx_message) { SpreeProductsImporter::Handler.get_file_data File.open("spec/support/products.xlsx", "r") }
      let!(:xls_message) { SpreeProductsImporter::Handler.get_file_data File.open("spec/support/products.xls", "r") }

      it "returns a success message" do
        xlsx_message[1].should eq "Products created successfully"
        xls_message[1].should eq "Products created successfully"
      end

      it "creates 3 Spree::Products" do  
        Spree::Product.count.should eq(3)
      end

      it "assigns a specific value to last product" do  
        Spree::Product.last.name.should eq "Product 3"
      end

      it "assigns a specific value to first product" do  
        Spree::Product.first.sku.should eq "1234a"
      end
    end

    context "with a invalid file" do
      let!(:message_error) { SpreeProductsImporter::Handler.get_file_data File.open("spec/support/products.txt", "r") }
      let!(:xlsx_invalid_message) { SpreeProductsImporter::Handler.get_file_data File.open("spec/support/invalid_products.xlsx", "r") }

      it "return a custom message when the file extension is not correctly" do
        message_error[1].should eq "Unknown file type: products.txt"
      end

      it "return a custom message when the file data is not correctly" do
        xlsx_invalid_message[1].should eq "An error found at line 2: name is required"
      end
    end

  end

  describe '#set_product_categories' do

    context "when taxons is not blank" do

      let!(:properties) { {"taxons" => "asdfg, Category 1, Category 2, Los"} }

      it "add the taxons found to product" do

        product    = FactoryGirl.create(:base_product)
        taxon_1    = FactoryGirl.create(:taxon, name: "Category 1")
        taxon_2    = FactoryGirl.create(:taxon, name: "Category 2")
        taxon_3    = FactoryGirl.create(:taxon, name: "asdf")
      
        product.taxons.count.should eq 0
        SpreeProductsImporter::Handler.set_product_categories product, properties

        product.taxons.should be_include taxon_1
        product.taxons.should be_include taxon_2
        product.taxons.should_not be_include taxon_3
      
      end

    end



    
    
  end
 
end