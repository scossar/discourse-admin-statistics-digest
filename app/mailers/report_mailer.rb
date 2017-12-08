require_relative '../helpers/report_helper'

class AdminStatisticsDigest::ReportMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ReportHelper
  helper :application
  default charset: 'UTF-8'

  helper_method :dir_for_locale, :logo_url, :header_color, :header_bgcolor, :anchor_color,
                :bg_color, :text_color, :highlight_bgcolor, :highlight_color, :body_bgcolor,
                :body_color, :report_date, :digest_title, :spacer_color, :table_border_style,
                :site_link, :statistics_digest_link, :superscript

  append_view_path Rails.root.join('plugins', 'discourse-admin-statistics-digest', 'app', 'views')
  default from: SiteSetting.notification_email

  def digest(months_ago, num_months: 2)
    months_ago = (0...num_months).to_a.map {|i| i + months_ago}

    # users
    period_dau = daily_active_users(months_ago, description_key: 'dau_description', display_threshold: -20)
    period_all_users = all_users(months_ago, description_key: 'all_users_description', display_threshold: -20)
    period_active_users = active_users(months_ago, description_key: 'active_users_description', display_threshold: -20)
    period_user_visits = user_visits(months_ago, description_key: 'user_visits_description', display_threshold: -20)
    period_health = health(months_ago, description_key: 'health_description', display_threshold: -20)
    period_new_users = new_users(months_ago, translation_key: 'new_users', description_key: 'new_users_description', display_threshold: -20)
    period_repeat_new_users = new_users(months_ago, repeats: 2, translation_key: 'repeat_new_users', description_key: 'repeat_new_users_description', display_threshold: -20)

    # content
    period_posts_created = posts_created(months_ago, archetype: 'regular')
    period_responses_created = posts_created(months_ago, translation_key: 'replies_created', description_key: 'responses_description', exclude_topic: true, display_threshold: -20)
    period_topics_created = topics_created(months_ago, description_key: 'topics_description', display_threshold: -20)
    period_message_created = topics_created(months_ago, archetype: 'private_message', description_key: 'messages_description')

    # actions
    period_posts_read = posts_read(months_ago)
    period_posts_flagged = flagged_posts(months_ago)
    period_posts_liked = user_actions(months_ago, 1, translation_key: 'posts_liked')
    period_topics_solved = user_actions(months_ago, 15, translation_key: 'topics_solved')

    header_metadata = [
      period_active_users,
      period_posts_created,
      period_posts_read
    ]

    # Separating the descriptions is awkward, but simplifies the mailer view.
    # Descriptions need to be ordered to correspond with their respective field.
    health_data = {
      title_key: 'statistics_digest.community_health_title',
      fields: [
        period_dau,
        period_active_users,
        period_health,
      ],
      descriptions: [
        {key: 'statistics_digest.dau_description'},
        {key: 'statistics_digest.dau_mau_description'}
      ]
    }

    user_data = {
      title_key: 'statistics_digest.users_section_title',
      fields: [
        period_all_users,
        period_new_users,
        period_repeat_new_users,
        period_user_visits
      ]
    }

    user_action_data = {
      title_key: 'statistics_digest.user_actions_title',
      fields: [
        period_posts_read,
        period_posts_liked,
        period_topics_solved,
        period_posts_flagged
      ]
    }

    content_data = {
      title_key: 'statistics_digest.content_title',
      fields: [
        period_topics_created,
        period_responses_created,
        period_message_created
      ]
    }

    data_array = [
      health_data,
      user_data,
      content_data,
      user_action_data
    ]

    subject = digest_title(months_ago[0])

    @data = {
      header_metadata: header_metadata,
      data_array: data_array,
      title: subject,
      subject: subject
    }

    admin_emails = User.where(admin: true).map(&:email).select {|e| e.include?('@')}

    mail(to: admin_emails, subject: subject)
  end

  private

  # users

  def all_users(months_ago, opts = {})
    all_users = report.all_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(all_users, 'all_users', opts)
  end

  def new_users(months_ago, opts = {})
    new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats opts[:repeats] ? opts[:repeats] : 1
    end

    compare_with_previous(new_users, 'new_users', opts)
  end

  def active_users(months_ago, opts = {})
    active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(active_users, 'active_users', opts)
  end

  def user_visits(months_ago, opts = {})
    user_visits = report.user_visits do |r|
      r.months_ago months_ago
    end

    compare_with_previous(user_visits, 'user_visits', opts)
  end

  def daily_active_users(months_ago, opts = {})
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    compare_with_previous(daily_active_users,'daily_active_users', opts)
  end

  def health(months_ago, opts = {})
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    monthly_active_users = report.active_users do |r|
      r.months_ago months_ago
    end

    current_dau = value_for_key(daily_active_users, 0, 'daily_active_users')
    prev_dau = value_for_key(daily_active_users, 1, 'daily_active_users')
    current_mau = value_for_key(monthly_active_users, 0, 'active_users')
    prev_mau = value_for_key(monthly_active_users, 1, 'active_users')

    current_health = calculate_health(current_dau, current_mau)
    prev_health = calculate_health(prev_dau, prev_mau)
    # todo: is there a standard way of comparing percentages?
    compare = current_health - prev_health

    {
      key: 'statistics_digest.dau_mau',
      value: format_percent(current_health),
      compare: format_percent(compare.round(2)),
      description_index: opts[:description_index],
      description_key: opts[:description_key] ? "statistics_digest.#{opts[:description_key]}" : nil,
      display: opts[:display_threshold] ? compare > opts[:display_threshold] : true
    }
  end

  # content

  def posts_created(months_ago, opts = {})
    posts_created = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype opts[:archetype] ? opts[:archetype] : 'regular'
      r.exclude_topic opts[:exclude_topic]
    end

    compare_with_previous(posts_created, 'posts_created', opts)
  end

  def topics_created(months_ago, opts = {})
    topics_created = report.topics_created do |r|
      r.months_ago months_ago
      r.archetype opts[:archetype] ? opts[:archetype] : 'regular'
    end

    compare_with_previous(topics_created, 'topics_created', opts)
  end

  # actions

  def posts_read(months_ago)
    posts_read = report.posts_read do |r|
      r.months_ago months_ago
    end

    compare_with_previous(posts_read, 'posts_read')
  end

  def flagged_posts(months_ago)
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    compare_with_previous(flagged_posts, 'flagged_posts')
  end

  def user_actions(months_ago, action_type, translation_key: nil)
    user_actions = report.user_actions do |r|
      r.months_ago months_ago
      r.action_type action_type
    end

    compare_with_previous(user_actions, 'actions', translation_key: translation_key)
  end

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

  def format_diff(diff)
    sprintf("%+d%", diff)
  end

  def format_percent(num)
    "#{num}%"
  end

  def compare_with_previous(arr, field_key, opts = {})
    # opts = opts || {}
    current = value_for_key(arr, 0, field_key)
    previous = value_for_key(arr, 1, field_key)
    compare = percent_diff(current, previous)
    formatted_compare = format_diff(compare)

    current = current.round(2) if current.is_a? Float
    if opts[:translation_key]
      text_key = "statistics_digest.#{opts[:translation_key]}"
    else
      text_key = "statistics_digest.#{field_key}"
    end

    {
      key: text_key,
      value: current,
      compare: formatted_compare,
      description_key: opts[:description_key] ? "statistics_digest.#{opts[:description_key]}" : nil,
      display: opts[:display_threshold] ? compare > opts[:display_threshold] : true
    }
  end

  def calculate_health(dau, mau)
    if dau > 0 && mau > 0
      (dau * 100 / mau).round(2)
    else
      0
    end
  end

  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
