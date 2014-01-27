Deface::Override.new( :virtual_path  => "spree/admin/shared/_product_sub_menu.html.erb",
                      :insert_bottom => "[data-hook='admin_product_sub_tabs']",
                      :text          => "
                      <%= tab :import %>
                      ",
                      :name          => "add_import_link_to_product_submemu.rb")