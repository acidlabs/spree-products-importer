# encoding: utf-8
require 'spec_helper'

describe "Feature: navigation" do

  stub_authorization!

  it "the products navigation subment contains the import products link" do
    visit spree.admin_products_path
    page.find_link("Import")["/admin/products/import"]
  end

end