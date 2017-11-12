include GoogleHelpers

ActiveAdmin.register_page 'Events' do

  menu priority: 1, label: proc { I18n.t('dashboard.menu.events') }

  content title: proc { I18n.t('dashboard.menu.events') } do
    div class: 'blank_slate_container', id: 'dashboard_default_message' do
      span class: 'blank_slate' do
        span I18n.t('active_admin.dashboard_welcome.welcome')
        small I18n.t('active_admin.dashboard_welcome.call_to_action')
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    columns do
      column do
        panel 'Upcoming Events' do
          ul do
            get_calendar.items.each do |event|
              start = event.start.date || event.start.date_time
              li do
                a(HREF: event.html_link, TARGET: 'lingo_lion_event') {"#{event.summary} (#{start})"}
              end
            end
          end
        end
      end
    end
  end # content

  page_action :all do
    respond_to do |format|
      format.html {}
    end
  end

  page_action :callback do
    respond_to do |format|
      format.html {}
    end
  end

  controller do
    layout :determine_active_admin_layout

    before_action except: [:callback] do
      @redirect_url = get_calendar
      render 'all' if @redirect_url.kind_of? String
    end

    # include GoogleHelpers

    def all
      get_calendar
    end

    def callback
      @target_url = google_oauth2_callback session
    end
  end
end
