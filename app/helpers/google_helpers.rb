require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/calendar_v3'

require 'fileutils'

OOB_URI = 'http://lingolion.me:3000'.freeze
APPLICATION_NAME = 'Lingo Lion'.freeze
CLIENT_SECRETS_PATH = 'config/google/credentials.json'.freeze
CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'lingo-lion.yaml')
CALENDAR_SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

module GoogleHelpers
  def credentials_for(scope)
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store, '/callback')
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    session[:target_url] = request.original_url
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

  def get_calendar
    credentials = credentials_for CALENDAR_SCOPE
    if credentials.nil? || credentials.is_a?(String)
      # Credentials were not found and the user needs to reauthorize
      puts 'User reauthorization required'
      return @redirect_url = credentials
    end

    puts "credentials => #{credentials}"

    # Initialize the API
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = credentials

    # Fetch the next 10 events for the user
    calendar_id = 'primary'
    calendar = nil
    begin
      calendar = service.list_events(calendar_id,
                                     max_results: 10,
                                     single_events: true,
                                     order_by: 'startTime',
                                     time_min: Time.now.iso8601)
    rescue => ex
      # More than likely the user revoked permissions
      puts ex
      revoke_google_user_auth CALENDAR_SCOPE
      return
    end

    calendar
  end
end
