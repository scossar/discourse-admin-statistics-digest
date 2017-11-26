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

  def digest(first_date, last_date)
    months_ago = 0
    active_users = active_users(months_ago)
    posts_created = posts_created(months_ago)
    dau = daily_active_users(months_ago)
    mau = user_visits(months_ago)
    health = (dau * 100 / mau).round(2)
    subject = digest_title(months_ago)

    header_metadata = [
      {key: 'statistics_digest.active_users', value: active_users},
      {key: 'statistics_digest.posts_created', value: posts_created},
      {key: 'statistics_digest.posts_read', value: posts_read(months_ago)}
    ]

    health_data = {
      title_key: 'statistics_digest.community_health_title',
      fields: [
        {key: 'statistics_digest.daily_active_users', value: dau},
        {key: 'statistics_digest.monthly_active_users', value: mau},
        {key: 'statistics_digest.dau_mau', value: "#{health}%",
         description_index: 0}
      ],
      descriptions: [
        {key: 'statistics_digest.dau_mau_description'}
      ]
    }

    user_data = {
      title_key: 'statistics_digest.users_section_title',
      fields: [
        {key: 'statistics_digest.new_users', value: new_users(months_ago)},
        {key: 'statistics_digest.repeat_new_users', value: repeat_new_users(months_ago, 2)},
        {key: 'statistics_digest.user_visits', value: user_visits(months_ago)}
      ]
    }

    content_data = {
      title_key: 'statistics_digest.content_title',
      fields: [
        {key: 'statistics_digest.topics_made', value: topics_made(months_ago)},
        {key: 'statistics_digest.posts_made', value: posts_created(months_ago)},
        {key: 'statistics_digest.posts_read', value: posts_read(months_ago)}
      ]
    }

    data_array = [
      health_data,
      user_data,
      content_data
    ]

    @data = {
      active_users: active_users,
      posts_created: posts_created,
      posts_read: posts_read(months_ago),
      header_metadata: header_metadata,
      data_array: data_array,
      title: digest_title(months_ago),
      subject: digest_title(months_ago),
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end

  # helper methods
  def dir_for_locale
    rtl? ? 'rtl' : 'ltr'
  end

  # Todo: fix this.
  def logo_url
    logo_url = SiteSetting.digest_logo_url
    logo_url = SiteSetting.logo_url if logo_url.blank? || logo_url =~ /\.svg$/i

    return nil if logo_url.blank? || logo_url =~ /\.svg$/i
    if logo_url !~ /http(s)?\:\/\//
      logo_url = "#{Discourse.base_url}#{logo_url}"
    end
    logo_url
  end

  def header_color
    "##{ColorScheme.hex_for_name('header_primary')}"
  end

  def header_bgcolor
    "##{ColorScheme.hex_for_name('header_background')}"
  end

  def anchor_color
    "##{ColorScheme.hex_for_name('tertiary')}"
  end

  def bg_color
    '#eeeeee'
  end

  def text_color
    '#222222'
  end

  def highlight_bgcolor
    '#2F70AC'
  end

  def highlight_color
    '#ffffff'
  end

  def body_bgcolor
    '#ffffff'
  end

  def body_color
    '#222222'
  end

  def report_date(months_ago)
    months_ago.month.ago.strftime('%b %Y')
  end

  def digest_title(months_ago)
    "#{I18n.t('statistics_digest.title')} #{report_date(months_ago)}"
  end

  def spacer_color(outer_count, inner_count = 0)
    outer_count == 0 && inner_count == 0 ? highlight_bgcolor : bg_color
  end

  def table_border_style(total_rows, current_row)
    unless total_rows - 1 == current_row
      "border-bottom:1px solid #dddddd;"
    end
  end

  def site_link(color)
    "<a style='text-decoration:none;color:#{color}' href='#{Discourse.base_url}' style='color: #{color}'>#{SiteSetting.title}</a>"
  end

  def statistics_digest_link(color)
    "<a style='text-decoration:none;color:#{color}' href='#{Discourse.base_url}/admin/plugins/admin-statistics-digest' style='color: #{color}'>#{t 'statistics_digest.here'}</a>"
  end

  def superscript(count)
    "<sup style='line-height:0;font-size:70%;vertical-align:top;mso-text-raise:60%'>[#{count}]</sup>"
  end

  private

  def active_users(months_ago = nil)
    active_users = report.active_users do |r|
      r.months_ago months_ago if months_ago
    end

    active_users[0]['active_users']
  end

  def monthly_active_users(months_ago)
    active_users = report.active_daily_users do |r|
      r.months_ago months_ago
    end

    active_users[0]['active_users']
  end

  def user_visits(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    user_visits[0]['user_visits']
  end

  def daily_active_users(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    total_visits = user_visits[0]['user_visits']
    days_in_period = user_visits[0]['days_in_period']

    (total_visits / days_in_period).round(2)
  end

  def posts_created(months_ago)
    posts = report.posts_created do |r|
      r.months_ago months_ago
    end

    posts[0]['posts_created']
  end

  def posts_read(months_ago)
    posts = report.posts_read do |r|
      r.months_ago months_ago
    end

    posts[0]['posts_read']
  end

  def topics_made(months_ago)
    topics = report.topics_made do |r|
      r.months_ago months_ago
    end

    topics[0]['topics_made']
  end

  def new_users(months_ago)
    new_users = report.new_users do |r|
      r.months_ago months_ago
    end

    new_users.count
  end

  def repeat_new_users(months_ago, repeats = 2)
    repeat_new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats repeats

    end

    repeat_new_users.count
  end

  def active(months_ago)
    report.active_users do |r|
      r.months_ago months_ago
    end
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end

end
