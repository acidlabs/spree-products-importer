module Spree
  
  module Admin

    ProductsController.class_eval do

      def import
      end

      def import_spreadsheet
        success, message = SpreeProductsImporter::Handler.get_file_data(params[:file])
        
        if success
          flash[:success] = message
        else
          @import_error_message = message
          flash[:error] = message
        end
  
        redirect_to import_admin_products_path
      end

    end

  end

end
