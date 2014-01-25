Spree::Core::Engine.routes.draw do

  namespace :admin do 

    resources :products do

      collection do
        get :import
        post :import_spreadsheet
      end
      
    end

  end

end
