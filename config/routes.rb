require 'subdomain_router'

Flightseein::Application.routes.draw do
  constraints(subdomain: Flightseein::Configuration.routing.default_subdomain) do
    resources :users, only: [ :new, :create ]
    resource :session, only: [ :new, :create, :destroy ]

    root(to: 'users#new')
  end

  constraints(SubdomainRouter::Constraint) do
    resource :account, only: [ :show, :edit, :update, :destroy ]
    resources :airports, only: [ :index, :show ] do
      resources :flights, only: :index
    end
    resources :flights, only: [ :index, :show, :edit, :update ]
    resources :imports, only: [ :new, :create, :show ]
    resources :people, only: [ :index, :show ] do
      resources :flights, only: :index
    end

    root(to: 'accounts#show')
  end
end
