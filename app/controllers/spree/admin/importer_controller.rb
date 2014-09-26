require 'dropbox_sdk'

module Spree
  module Admin
    class ImporterController < Spree::Admin::BaseController
      # include Spree::Backend::Callbacks

      # GET admin/importer
      def index
        if Spree::Config.dropbox_api_enabled
          @authorize_url = DropboxOAuth2FlowNoRedirect.new(DROPBOX_API[:dropbox_api_key], DROPBOX_API[:dropbox_api_secret]).start()
        end
      end

      # GET admin/importer/template
      def template
        file = File.open(Spree::Config[:sample_file])

        send_data file.read, :filename => File.basename(Spree::Config[:sample_file])
      end

      # POST admin/importer
      def create
        # ToDo - Refactor!
        if Spree::Config.dropbox_api_enabled
          if params[:access_token].present? and params[:file]
            if SpreeProductsImporter::Handler.import(params[:file], access_token: params[:access_token])
              flash[:success] = I18n.t(:importing, scope: [:spree, :spree_products_importer, :messages, :controller])
            else
              flash[:error] = I18n.t(:error, scope: [:spree, :spree_products_importer, :messages, :controller])
            end
          elsif params[:file]
            flash[:error] = I18n.t(:access_token_required, scope: [:spree, :spree_products_importer, :messages, :controller])
          elsif params[:access_token].present?
            flash[:error] = I18n.t(:file_required, scope: [:spree, :spree_products_importer, :messages, :controller])
          else
            flash[:error] = I18n.t(:all_fields_required, scope: [:spree, :spree_products_importer, :messages, :controller])
          end
        else
          if params[:file]
            if SpreeProductsImporter::Handler.import(params[:file])
              flash[:success] = I18n.t(:importing, scope: [:spree, :spree_products_importer, :messages, :controller])
            else
              flash[:error] = I18n.t(:error, scope: [:spree, :spree_products_importer, :messages, :controller])
            end
          else
            flash[:error] = I18n.t(:file_required, scope: [:spree, :spree_products_importer, :messages, :controller])
          end
        end

        redirect_to admin_importer_index_path
      end
    end
  end
end
