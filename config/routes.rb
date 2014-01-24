Spree::Core::Engine.routes.draw do

  namespace :admin do 

    resources :products do
      collection do
	get :import
	post :load_data
      end		
    end

  end

end
