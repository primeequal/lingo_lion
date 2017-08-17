require 'google/apis/calendar_v3'

SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

ActiveAdmin.register_page "Events" do

  menu priority: 1, label: proc {I18n.t("dashboard.menu.events")}

  content title: proc {I18n.t("dashboard.menu.events")} do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        span I18n.t("active_admin.dashboard_welcome.welcome")
        small I18n.t("active_admin.dashboard_welcome.call_to_action")
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content

  page_action :all do
    respond_to do |format|
      format.any {}
    end
  end

  page_action :callback do
    respond_to do |format|
      format.any {}
    end
  end

  controller do
    include GoogleHelpers

    def all
      credentials = credentials_for SCOPE
      if credentials.nil? || credentials.kind_of?(String)
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
      begin
        response = service.list_events(calendar_id,
                                       max_results: 10,
                                       single_events: true,
                                       order_by: 'startTime',
                                       time_min: Time.now.iso8601)
      rescue => ex
        # More than likely the user revoked permissions
        puts ex
        revoke_google_user_auth SCOPE
        return
      end

      puts "Upcoming events:"
      puts "No upcoming events found" if response.items.empty?
      response.items.each do |event|
        start = event.start.date || event.start.date_time
        puts "- #{event.summary} (#{start})"
      end
    end

    def callback
      @target_url = google_oauth2_callback session
    end
  end
end
