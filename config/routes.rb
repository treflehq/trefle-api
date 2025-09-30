require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'sidekiq-status/web'

Rails.application.routes.draw do # rubocop:todo Metrics/BlockLength

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  root 'home#index'
  get '/about', to: 'home#about', as: 'about'
  get '/terms', to: 'home#licence', as: 'terms'
  get '/stats', to: 'home#stats', as: 'stats'
  get '/profile', to: 'profile#index', as: 'profile'

  namespace 'api' do
    namespace 'v1' do
      get '/', to: 'home#index'
      get '/me', to: 'users#me'

      resources :kingdoms, only: %i[index show]
      resources :subkingdoms, only: %i[index show]
      resources :division_orders, only: %i[index show]
      resources :division_classes, only: %i[index show]
      resources :divisions, only: %i[index show]
      resources :families, only: %i[index show] do
        resources :genus, only: %i[index show]
      end
      resources :genus, only: %i[index show] do
        resources :plants, only: %i[index show]
        resources :species, only: %i[index show]
      end

      resources :plants, only: %i[index show] do
        resources :species, only: %i[index show]
        post '/report', action: :report, on: :member
        get '/search', action: :search, on: :collection
      end

      resources :species, only: %i[index show] do
        resources :record_corrections, only: %i[index], path: 'corrections'
        post '/report', action: :report, on: :member
        get '/search', action: :search, on: :collection
      end

      resources :record_corrections, path: 'corrections', only: %i[index show] do
        post '/:record_type/:record_id', to: 'record_corrections#create', on: :collection
        get :mine, to: 'record_corrections#index', on: :collection, mine: true
      end

      resources :zones, path: 'distributions', only: %i[index show] do
        resources :plants, only: %i[index show]
        resources :species, only: %i[index show]
      end
    end

    namespace 'auth' do
      post '/claim', to: 'auth#claim'
    end

    match '*all', controller: 'api', action: 'cors_preflight_check', via: [:options]
  end

  namespace 'explore' do
    get '/', to: 'species#index'
    get '/data', to: 'data#index'
    resources :species, only: %i[index show] do
      resources :record_corrections, only: %i[index], path: 'corrections'
    end
    resources :genus, only: %i[index show] do
    end
    resources :record_corrections, path: 'corrections', only: %i[index show] do

    end
  end

  namespace 'management' do
    authenticate :user, ->(user) { user.admin? } do
      mount PgHero::Engine, at: 'pghero'
      mount Sidekiq::Web => '/sidekiq'
    end

    get '/', to: 'plants#index'

    resources :users
    resources :user_queries do
      get :stats, on: :collection
    end
    resources :subkingdoms
    resources :species_proposals
    resources :species_images do
      get :chaos, on: :collection
      patch :as_main_image, on: :member
    end
    resources :record_corrections do
      patch :accept, on: :member
      patch :reject, on: :member
    end

    resources :species do
      resources :species_images do
        get :chaos, on: :collection
      end
      patch :refresh, on: :member
    end

    resources :sessions
    resources :plants
    resources :major_groups
    resources :kingdoms
    resources :genuses
    resources :foreign_sources_plants
    resources :foreign_sources
    resources :families
    resources :divisions
    resources :division_orders
    resources :division_classes
  end

end
