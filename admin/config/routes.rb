Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :two_factor, only: %i[ new create ]
  resource :two_factor_setup, only: %i[ show create ]

  root "dashboard#show"

  resources :clients do
    post :verify_peppol, on: :member
    resources :contacts, only: %i[ new create edit update destroy ]
  end
  resources :projects
  resources :time_entries, except: :show do
    post :bill, on: :collection
  end
  resources :packs, except: :index
  resources :contracts do
    post :bill, on: :member
  end
  resources :plans do
    resources :prices, only: %i[ create destroy ], controller: "plan_prices"
  end
  resources :hourly_rates, only: %i[ index create destroy ]
  resources :fixed_costs, except: :show
  resources :invoices do
    member do
      post :issue
      post :deliver
      post :credit_note
      get :pdf
      get :ubl
    end
  end
  resource :company_profile, only: %i[ show edit update ]
  resources :suppliers
  resources :expense_categories, except: :show do
    patch :validate, on: :member
  end
  resources :comments, only: %i[ create update destroy ]
  resources :audit_events, only: :index
  resources :import_runs, only: %i[ index show create ]
  resources :users, except: :show do
    post :reset_two_factor, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
