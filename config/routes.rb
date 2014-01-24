Spree::Core::Engine.routes.draw do

	get  "products/import" => "products#import"
	post "load_data"       => "products#load_data" 

end
