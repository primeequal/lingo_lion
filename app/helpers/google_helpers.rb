require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'http://lingolion.me:3000'.freeze
APPLICATION_NAME = 'Lingo Lion'.freeze
CLIENT_SECRETS_PATH = 'config/google/credentials.json'.freeze
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'lingo-lion.yaml')

module GoogleHelpers
  def credentials_for(scope)
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store, '/callback')
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    puts "session[:auth_code] => #{session[:auth_code]}"
    if !session[:auth_code].nil?
      credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: session[:auth_code], base_url: OOB_URI, redirect_uri: '/admin/admin_users'
      )
      session[:auth_code] = nil
      return credentials
    elsif credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI, scope: scope, redirect_uri: '/callback')
      Rails.logger.debug 'Redirecting to Google OAuth2 external page: ' + url
      session[:target_url] = request.original_url
      return url
    end
    credentials
  end

  def google_oauth2_callback(session)
    Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
    session[:auth_code] = request[:code]
    target_url = session[:target_url]
    session[:target_url] = nil
    target_url
  end

  def revoke_google_user_auth(scope)
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store, '/callback')
    user_id = 'default'

    # Do this if authorization was revoked by the user
    begin
      authorizer.revoke_authorization user_id
    rescue => ex
      puts ex
    end
  end
end
