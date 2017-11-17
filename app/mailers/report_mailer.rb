class AdminStatisticsDigest::ReportMailer < ActionMailer::Base

  include Rails.application.routes.url_helpers
  include ApplicationHelper
  helper :application
  default charset: 'UTF-8'

  helper_method :dir_for_locale, :logo_url, :header_color, :header_bgcolor, :anchor_color,
                :bg_color, :text_color, :highlight_bgcolor, :highlight_color, :body_bgcolor,
                :body_color, :report_date, :digest_title, :spacer_color

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(first_date, last_date)

    report_date = "#{first_date.to_s(:short)} - #{last_date.to_s(:short)} #{last_date.strftime('%Y')}"
    subject = "Discourse Admin Statistic Report #{report_date}"
    header_metadata = [
      {key: 'admin_statistics_digest.active_users', value: active_users},
      {key: 'admin_statistics_digest.posts_made', value: posts_made},
      {key: 'admin_statistics_digest.posts_read', value: posts_read}
    ]

    health_data = {
      title_key: 'admin_statistics_digest.community_health_title',
      fields: [
        {key: 'admin_statistics_digest.daily_active_users', value: daily_active_users},
        {key: 'admin_statistics_digest.monthly_active_users', value: monthly_active_users},
        {key: 'admin_statistics_digest.dau_mau', value: health,
         description: 'admin_statistics_digest.dau_mau_description'}
      ]
    }

    post_data = {
      title_key: 'admin_statistics_digest.posts_data_title',
      fields: [
        {key: 'admin_statistics_digest.posts_made', value: posts_made},
        {key: 'admin_statistics_digest.posts_read', value: posts_read}
      ]
    }

    data_array = [
      health_data,
      post_data
    ]

    limit = 5
    @data = {
      top_new_registered_users: top_new_registered_users(first_date, limit),
      top_non_staff_users: top_non_staff_users(first_date, limit),
      demoted_regulars_this_month: demoted_regulars_this_month(first_date, last_date, limit),
      popular_posts: popular_posts(first_date, last_date, limit),
      popular_topics: popular_topics(first_date, last_date, limit),
      most_liked_posts: most_liked_posts(first_date, last_date, limit),
      most_replied_topics: most_replied_topics(first_date, last_date, limit),
      active_responders: active_responders(first_date, last_date, limit),

      header_metadata: header_metadata,
      active_users: active_users,
      posts_made: posts_made,
      posts_read: posts_read,
      new_users: new_users,
      repeat_new_users: repeat_new_users,
      dau: daily_active_users,
      mau: monthly_active_users,
      health: health,
      #health_data: health_data,
      data_array: data_array,

      title: subject,
      subject: subject,
      report_date: report_date
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end


  # helper methods
  # todo: can these be moved to a concern?

  def dir_for_locale
    rtl? ? 'rtl' : 'ltr'
  end

  def logo_url
    logo_url = SiteSetting.digest_logo_url
    logo_url = SiteSetting.logo_url if logo_url.blank? || logo_url =~ /\.svg$/i

    return nil if logo_url.blank? || logo_url =~ /\.svg$/i
    if logo_url !~ /http(s)?\:\/\//
      logo_url = "#{Discourse.base_url}#{logo_url}"
    end
    logo_url
  end

  # todo: add '#' to hex value
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

  def report_date
    "Oct 2017"
  end

  def digest_title
    "#{I18n.t('admin_statistics_digest.title')} #{report_date}"
  end

  def spacer_color(outer_count, inner_count = 0)
    outer_count == 0 && inner_count == 0 ? highlight_bgcolor : bg_color
  end

  private

  # stubbed methods

  def active_users
    2456
  end

  def posts_made
    654
  end

  def posts_read
    2473
  end

  def new_users
    147
  end

  def repeat_new_users
    76
  end

  def daily_active_users
    273
  end

  def monthly_active_users
    769
  end

  def health
    daily_active_users / monthly_active_users
  end

  # end of stubbed methods

  def top_new_registered_users(signed_up_date, limit)
    report.active_users do |r|
      r.signed_up_since signed_up_date
      r.include_staff false
      r.limit limit
    end
  end

  def top_non_staff_users(signed_up_date, limit)
    report.active_users do |r|
      r.signed_up_before signed_up_date
      r.limit limit
      r.include_staff false
    end
  end

  def demoted_regulars_this_month(first_date, last_date, limit)
    last_month_fd = first_date - 1.month
    last_month_ld = last_date - 1.month
    two_months_ago_fd = first_date - 2.months
    two_months_ago_ld = last_date - 2.months

    active_2_months_ago = report.active_users do |r|
      r.signed_up_before last_month_fd
      r.active_range two_months_ago_fd..two_months_ago_ld
      r.include_staff false
      r.limit limit
    end

    active_1_months_ago = report.active_users do |r|
      r.signed_up_before last_month_fd
      r.active_range two_months_ago_ld..last_month_fd
      r.include_staff false
      r.limit limit
    end

    this_month = report.active_users do |r|
      r.signed_up_between from: last_month_fd, to: last_month_ld
      r.active_range last_month_fd..last_month_ld
      r.include_staff false
      r.limit limit
    end

    [
      active_2_months_ago.map {|s| {user_id: s['user_id'], username: s['username'], name: s['name']}.with_indifferent_access},
      active_1_months_ago.map {|s| {user_id: s['user_id'], username: s['username'], name: s['name']}.with_indifferent_access}
    ].flatten.uniq - this_month.map {|s| {user_id: s['user_id'], username: s['username'], name: s['name']}.with_indifferent_access}
  end

  def popular_posts(first_date, last_date, limit)
    report.popular_posts do |r|
      r.limit limit
      r.popular_by_date first_date, last_date
    end
  end

  def popular_topics(first_date, last_date, limit)
    report.popular_topics do |r|
      r.limit limit
      r.popular_by_date first_date, last_date
    end
  end

  def most_liked_posts(first_date, last_date, limit)
    report.most_liked_posts do |r|
      r.limit limit
      r.active_range first_date..last_date
    end
  end

  def most_replied_topics(first_date, last_date, limit)
    report.most_replied_topics do |r|
      r.limit limit
      r.most_replied_by_date first_date, last_date
    end
  end

  def active_responders(first_date, last_date, limit)
    result = []
    AdminStatisticsDigest::ActiveResponder.monitored_topic_categories.each do |category_id|
      responders = report.active_responders do |r|
        r.limit limit
        r.topic_category_id category_id
        r.active_range first_date..last_date
      end

      result.push({
                    category_name: Category.find(category_id).name,
                    responders: responders
                  }.with_indifferent_access)
    end
    result
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end

end
