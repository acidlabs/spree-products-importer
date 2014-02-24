require 'sidekiq/web'

Spree::Core::Engine.routes.draw do
    # authenticate :admin do
  #   mount Sidekiq::Web => '/sidekiq'
  # end

  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end

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
