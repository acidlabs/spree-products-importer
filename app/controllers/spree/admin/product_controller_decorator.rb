module Spree

  ProductController.class_eval do

    def import
    end

    def load_data
      success, message = SpreeProductsImporter::Handler.import(params[:file])
      redirect_to import_product_path, success ? {notice: message} : {notice: message}
    end

  end

end