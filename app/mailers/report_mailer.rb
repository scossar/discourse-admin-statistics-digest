class AdminStatisticsDigest::ReportMailer < ActionMailer::Base

  include Rails.application.routes.url_helpers
  include ApplicationHelper
  helper :application
  default charset: 'UTF-8'

  helper_method :dir_for_locale, :logo_url, :header_color, :header_bgcolor, :anchor_color,
                :bg_color, :text_color, :highlight_bgcolor, :highlight_color, :body_bgcolor,
                :body_color, :report_date, :digest_title, :spacer_color, :table_border_style,
                :site_link, :statistics_digest_link, :superscript

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(months_ago)
    # set months_ago to 1 for testing
    months_ago = [0, 1, 2, 3]

    active_users_for_period = active_users(months_ago)
    visits_for_period = user_visits(months_ago)

  end


  private

  def active_users(months_ago)
    active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    puts "ACTIVEUSERS #{active_users}"
  end

  def user_visits(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    puts "USERVISITS #{user_visits}"
  end


  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
