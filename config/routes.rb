Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :products do
      collection do
        get :import
        get :import_template
        post :import_spreadsheet
      end
    end
  end
end
