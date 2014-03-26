module Spree
  module Admin
    ProductsController.class_eval do

      def import
      end

      def import_spreadsheet
        if params[:file]
          success, message = Spree::Config.importer.constantize.get_file_data(params[:file])

          if success
            flash[:success] = message
          else
            @import_error_message = message
            flash[:error] = message
          end
        else
          flash[:error] = I18n.t(:file_required, scope: [:spree, :spree_products_importer, :messages])
        end

        redirect_to import_admin_products_path
      end

      def import_template
        file= File.open(Spree::Config[:sample_file])
        send_data file.read, :filename => "example.xls"
      end
    end
  end
end
