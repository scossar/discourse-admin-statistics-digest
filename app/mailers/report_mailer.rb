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

    # users
    period_all_users = all_users(months_ago)
    period_active_users = active_users(months_ago)
    period_visits = user_visits(months_ago)
    period_dau = daily_active_users(months_ago)
    period_new_users = new_users(months_ago)
    period_repeat_new_users = new_users(months_ago, repeats: 2)

    # content
    period_posts = posts_created(months_ago, archetype: 'regular')
    period_responses = posts_created(months_ago, archetype: 'regular', exclude_topic: true)
    period_topics = topics_created(months_ago)

    # actions
    period_posts_read = posts_read(months_ago)
    period_flags = flagged_posts(months_ago)
    period_likes = user_actions(months_ago, action_type: 1)
  end

  # helper methods
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
    months_ago.month.ago.strftime('%B %Y')
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

  # users

  def all_users(months_ago)
    all_users = report.all_users do |r|
      r.months_ago months_ago
    end

    puts "ALL USERS COMPARE #{compare_with_previous(all_users, 'all_users')}"
  end

  def new_users(months_ago, repeats: 1)
    new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats repeats
    end

    puts "NEW USERS COMPARE #{compare_with_previous( new_users, 'new_users')}"
  end

  def active_users(months_ago)
    active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    puts "ACTIVEUSERS COMPARE #{compare_with_previous(active_users, 'active_users')}"
  end

  def user_visits(months_ago)
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    puts "USERVISITS COMPARE #{compare_with_previous(user_visits, 'user_visits')}"
  end

  def daily_active_users(months_ago)
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    puts "DAU COMPARE #{compare_with_previous(daily_active_users, 'daily_active_users')}"
  end

  # content

  def posts_created(months_ago, archetype: 'regular', exclude_topic: nil)
    posts_created = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype archetype
      r.exclude_topic exclude_topic if exclude_topic
    end

    puts "POSTS CREATED COMPARE #{compare_with_previous(posts_created, 'posts_created')}"
  end

  def topics_created(months_ago, archetype: 'regular')
    topics_created = report.topics_created do |r|
      r.months_ago months_ago
      r.archetype archetype
    end

    puts "TOPICS CREATED COMPARE #{compare_with_previous(topics_created, 'topics_created')}"
  end

  # actions

  def posts_read(months_ago)
    posts_read = report.posts_read do |r|
      r.months_ago months_ago
    end

    puts "POSTS READ COMPARE #{compare_with_previous(posts_read, 'posts_read')}"
  end

  def flagged_posts(months_ago)
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    puts "FLAGGED POSTS COMPARE #{compare_with_previous(flagged_posts, 'flagged_posts')}"
  end

  def user_actions(months_ago, action_type:)
    user_actions = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type action_type
    end

    puts "USER ACTIONS COMPARE #{compare_with_previous(user_actions, 'actions')}"
  end

  # todo: make sure all queries default to 0. Double check conditional.
  def percent_diff(current, previous)
    if current && previous && previous > 0
      (current - previous) * 100.0 / previous
    elsif current
      100.00
    else
      0
    end
  end

  def value_for_key(arr, pos, key)
    arr[pos][key] if arr[pos]
  end

  def formatted_diff(diff)
    sprintf("%+d%", diff)
  end

  def compare_with_previous(arr, key, display_threshold = -20)
    current = value_for_key(arr, 0, key)
    previous = value_for_key(arr, 1, key)
    compare = percent_diff(current, previous)

    {current: current, previous: previous, compare: compare, formatted_compare: formatted_diff(compare), display: compare > display_threshold}
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
