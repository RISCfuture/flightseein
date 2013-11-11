require 'subdomain_router'

Flightseein::Application.routes.draw do
  constraints(subdomain: '') do
    get '' => redirect { |_, request| "http://www.#{request.host_with_port}" }
    get '*glob' => redirect { |_, request| "http://www.#{request.host_with_port}#{request.fullpath}" }
  end

  constraints(subdomain: SubdomainRouter::Config.default_subdomain) do
    resources :users, only: [:new, :create]
    resource :session, only: [:new, :create, :destroy]
    resources :photographs, only: :index

    root(to: 'users#new')

    require 'admin_constraint'
    require 'sidekiq/web'
    mount Sidekiq::Web => 'sidekiq'#, constraints: AdminConstraint.new
  end

  constraints(SubdomainRouter::Constraint) do
    resource :account, only: [:show, :edit, :update, :destroy]
    resources :airports, only: [:index, :show] do
      resources :flights, only: :index
    end
    resources :flights, only: [:index, :show, :edit, :update] do
      resources :photographs, only: [:index, :create]
    end
    resources :imports, only: [:new, :create, :show]
    resources :people, only: [:index, :show] do
      resources :flights, only: :index
    end

    get '' => 'accounts#show'
  end
end
