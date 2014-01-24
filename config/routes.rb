Spree::Core::Engine.routes.draw do

	get  "products/import" => "products#import", as: :import_product    
	post "load_data" => "products#load_data", as: :load_data_product

end
