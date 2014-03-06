class NotificationMailer < ActionMailer::Base
  default from: Spree::Config[:importer_from]

  def error filename, row, error, data
    @filename  = filename
    @row       = row
    @error     = error
    @data      = data

    mail to: Spree::Config[:importer_to], subject: I18n.t(:error, scope: [:spree, :spree_products_importer, :messages, :notification], filename: filename)
  end

  def successfully filename
    @filename  = filename

    mail to: Spree::Config[:importer_to], subject: I18n.t(:success, scope: [:spree, :spree_products_importer, :messages, :notification], filename: filename)
  end
end
