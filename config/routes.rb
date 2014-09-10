require 'sidekiq/web'

Spree::Core::Engine.routes.draw do
  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :admin do
    resources :importer, only: [:index, :create] do
      collection do
        get :template
      end
    end
  end
end
