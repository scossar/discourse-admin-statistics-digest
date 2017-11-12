class AdminStatisticsDigest::ReportMailer < ActionMailer::Base

  include Rails.application.routes.url_helpers

  # This doesn't all need to be included.

  include UserNotificationsHelper
  include ApplicationHelper
  helper :application, :user_notifications
  default charset: 'UTF-8'

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(first_date, last_date)

    logo_url = SiteSetting.logo_url
    logo_url = logo_url.include?('http') ? logo_url : Discourse.base_url + logo_url
    report_date = "#{first_date.to_s(:short)} - #{last_date.to_s(:short)} #{last_date.strftime('%Y')}"
    subject = "Discourse Admin Statistic Report #{report_date}"
    # todo: use label key.
    counts = [{label_key: 'active users', value: active_users(first_date, last_date)},
              {label_key: 'posts made', value: posts_made(first_date, last_date)},
              {label_key: 'pages read', value: pages_read(first_date, last_date)}]

    limit = 5
    @data = {
      header_color: '000000',
      header_bgcolor: 'ffffff',
      counts: counts,
      active_users: active_users(first_date, last_date),
      posts_made: posts_made(first_date, last_date),
      pages_read: pages_read(first_date, last_date),
      new_users: new_users(first_date),
      repeat_new_users: repeat_new_users(first_date, last_date),
      dau: daily_active_users(first_date, last_date),
      mau: monthly_active_users(first_date, last_date),
      health: health(first_date, last_date),

      title: subject,
      subject: subject,
      logo_url: logo_url,
      report_date: report_date
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end

  private
  def active_users(first_date, last_date)
    users = report.active_users do |r|
      r.active_range first_date..last_date
    end

    users.count
  end

  def posts_made(first_date, last_date)
    posts = report.posts_made do |r|
      r.active_range first_date..last_date
    end

    posts.count
  end

  def pages_read(first_date, last_date)
    pages = report.pages_read do |r|
      r.active_range first_date..last_date
    end

    pages.count
  end


  def new_users(signed_up_date)
    users = report.active_users do |r|
      r.signed_up_since signed_up_date
      r.include_staff false
    end

    users.count
  end

  def repeat_new_users(first_date, last_date)
    users = report.repeat_new_users do |r|
      r.active_range first_date..last_date
    end

    users.count
  end

  def monthly_active_users(first_date, last_date)
    users = report.daily_active_users do |r|
      r.active_range first_date..last_date
    end

    users.count
  end

  def daily_active_users(first_date, last_date)

    monthly_active_users(first_date, last_date) / 30
  end

  def health(first_date, last_date)

    daily_active_users(first_date, last_date) / monthly_active_users(first_date, last_date)
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end

end
