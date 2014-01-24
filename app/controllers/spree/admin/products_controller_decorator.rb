module Spree

  ProductsController.class_eval do

    def import
    end

    def load_data
      success, message = SpreeProductsImporter::Handler.import(params[:file])
      redirect_to import_admin_products_path, success ? {notice: message} : {notice: message}
    end

  end

end
