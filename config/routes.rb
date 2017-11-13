Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users, controllers: {
      sessions: 'users/sessions'
  }

  ActiveAdmin.routes(self)
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  as :admin_users do
    get '/callback', to: 'admin/events#callback'
  end
end
