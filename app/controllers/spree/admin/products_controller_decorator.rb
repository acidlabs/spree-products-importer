module Spree
  
  module Admin

    ProductsController.class_eval do

      def import
      end

      def import_spreadsheet
        success, message = SpreeProductsImporter::Handler.get_file_data(params[:file])
        redirect_to import_admin_products_path, notice: message
      end

    end

  end

end
