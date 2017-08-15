require 'googleauth'
require 'googleauth/web_user_authorizer'
require 'googleauth/stores/redis_token_store'
require 'redis'

ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  collection_action :auth, method: :get do

  end

  collection_action :callback, method: :get do

  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  controller do
    def auth
      client_id = Google::Auth::ClientId.from_file('config/google/credentials.json')
      scope = ['https://www.googleapis.com/auth/calendar']
      token_store = Google::Auth::Stores::RedisTokenStore.new(host: 'lingolion.me', port: 6379)
      authorizer = Google::Auth::WebUserAuthorizer.new(client_id, scope, token_store, '/callback')

      user_id = params[:user_id]

      # if session[:credentials].nil?
      #   begin
      #     credentials = authorizer.get_credentials(user_id, request)
      #   rescue StandardError => error
      #     Rails.logger.debug error
      #   end
      # end

      if session[:credentials].nil?
        redirect_to authorizer.get_authorization_url(login_hint: user_id, request: request,
                                                     redirect_to: '/admin/admin_users')
      end

      "Congrats!"
    end

    def callback
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      session[:credentials] = params[:code]
      # session[:credentials].fetch_access_token!
      redirect_to target_url
    end
  end
end
