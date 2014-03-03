# encoding: utf-8
require 'spec_helper'

describe "SpreeProductsImporter::Handler" do

  describe '#validate_product_data' do

    let!(:valid_data_without_properties) {{ 
      "name" => 'Product 2',
      "price" => 80000,
      "sku" => "ABC1234",
      "description" => "The best product in the world",
      "ean_13" => "ean123",
      "sale_price" => 90000,
      "technical_description" => "aaa bbb ccc"
    }}
    let!(:valid_data) {{ "name" => 'Product 1', "price" => 80000, "sku" => "ABC1234", "property1" => "A", "property2" => "B"}}
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
        result.last[:product][:description].should eq "The best product in the world"
        result.last[:product][:ean_13].should eq "ean123"
        result.last[:product][:sale_price].should eq 90000
        result.last[:product][:technical_description].should eq "aaa bbb ccc"
      end

      it "returns product properties in a hash" do
        result = SpreeProductsImporter::Handler.validate_product_data(valid_data, 2)

        result.last[:values]["property1"].should eq "A"
        result.last[:values]["property2"].should eq "B"
      end

      context "with valid arguments without product properties" do
        it "returns a empty properties hash" do
          result = SpreeProductsImporter::Handler.validate_product_data(valid_data_without_properties, 2)

          result.last[:values].should be_empty
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
        Spree::Product.first.price.should eq 30
      end

      context "with a numeric sku" do
        it "saves correctly the value without decimal values" do
          Spree::Product.first.sku.should eq "1234"
        end
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

      let!(:values) { { "taxons" => "asdfg", 
                        "taxons2" => "Category 1", 
                        "taxons3" => "Category 2", 
                        "taxons4" => "Los"} }

      it "add the taxons found to product" do

        product    = FactoryGirl.create(:base_product)
        taxon_1    = FactoryGirl.create(:taxon, name: "Category 1")
        taxon_2    = FactoryGirl.create(:taxon, name: "Category 2")
        taxon_3    = FactoryGirl.create(:taxon, name: "asdf")
      
        product.taxons.count.should eq 0
        SpreeProductsImporter::Handler.set_product_categories product, values

        product.taxons.should be_include taxon_1
        product.taxons.should be_include taxon_2
        product.taxons.should_not be_include taxon_3
      
      end

    end

  end

  describe '#set_product_origin' do

    context "when origin is not blank" do

      before(:each) do
        @values  = { "origin" => "Falabella" }
        @values2 = { "origin" => "Falabella1" }
        @taxon   = FactoryGirl.create(:taxon, name: "Falabella")
      end

      it "add the origin found to product" do
        product = FactoryGirl.create(:base_product)
        
        product.taxons.count.should eq 0
        SpreeProductsImporter::Handler.set_product_origin product, @values

        product.taxons.should be_include @taxon
        product.taxons.count.should eq 1
      end

      context "and taxon name is not found" do
        it "add the origin found to product" do
          product = FactoryGirl.create(:base_product)

          product.taxons.count.should eq 0
          SpreeProductsImporter::Handler.set_product_origin product, @values2

          product.taxons.should_not be_include @taxon
          product.taxons.count.should eq 0
        end
      end
      
    end

  end


  describe '#set_product_brand' do

    context "when brand is not blank" do

      before(:each) do
        @values  = { "brand" => "Brand 1" }
        @values2 = { "brand" => "Brand 2" }
        @taxon   = FactoryGirl.create(:taxon, name: "Brand 1")
      end

      it "add the brand found to product" do
        product = FactoryGirl.create(:base_product)
        
        product.taxons.count.should eq 0
        SpreeProductsImporter::Handler.set_product_brand product, @values

        product.taxons.should be_include @taxon
        product.taxons.count.should eq 1
      end

      context "and taxon name is not found" do
        it "add the origin found to product" do
          product = FactoryGirl.create(:base_product)

          product.taxons.count.should eq 0
          Spree::Taxon.find_by_name(@values2["brand"]).should be_nil
          SpreeProductsImporter::Handler.set_product_brand product, @values2

          taxon = Spree::Taxon.find_by_name(@values2["brand"])

          taxon.should_not be_nil
          product.taxons.should_not be_include @taxon
          product.taxons.count.should eq 1
          expect(taxon.parent_id).to be_blank
        end

        context "and a parent exist" do
          it "add 'Marcas' as parent taxon" do
            parent  = FactoryGirl.create(:taxon, name: 'Marcas')
            product = FactoryGirl.create(:base_product)

            SpreeProductsImporter::Handler.set_product_brand product, @values2

            taxon = Spree::Taxon.find_by_name(@values2["brand"])

            expect(taxon.parent_id).to eq(parent.id)
          end
        end

      end

    end

  end

end