Rails.application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users, controllers: {
      sessions: 'users/sessions', registrations: 'users/registrations', passwords: 'users/passwords',
      omniauth_callbacks: 'users/omniauth_callbacks'
  }

  as :admin_users do
    get '/callback', to: 'admin/events#callback'
  end
end
