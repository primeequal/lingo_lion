require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'http://lingolion.me:3000'
APPLICATION_NAME = 'Lingo Lion'
CLIENT_SECRETS_PATH = 'config/google/credentials.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "lingo-lion.yaml")
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

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
    respond_to do |format|
      format.any { @credentials.to_a.to_s unless @credentials.nil? }
    end
  end

  collection_action :auth_refresh, method: :get do
    respond_to do |format|
      format.any { @credentials.to_a.to_s unless @credentials.nil? }
    end
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
      FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

      client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store, '/callback')
      user_id = 'default'
      credentials = authorizer.get_credentials(user_id)
      if credentials.nil?
        url = authorizer.get_authorization_url(base_url: OOB_URI, scope: SCOPE, redirect_uri: admin_admin_users_path)
        puts "Open the following URL in the browser and enter the " +
                 "resulting code after authorization"
        puts url
        redirect_to url
      end
      @credentials
    end

    def auth_refresh
      FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

      client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
      token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      user_id = 'default'
      @credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: session[:auth_code], base_url: OOB_URI, redirect_uri: admin_admin_users_path)
    end

    def callback
      target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
      session[:auth_code] = params[:code]
      # session[:credentials].fetch_access_token!
      redirect_to target_url
    end
  end
end
