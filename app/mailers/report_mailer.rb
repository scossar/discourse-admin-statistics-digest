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
    all_users_for_period = all_users(months_ago)
    active_users_for_period = active_users(months_ago)
    visits_for_period = user_visits(months_ago)
    dau = daily_active_users(months_ago)
    period_new_users = new_users(months_ago)
    period_repeat_new_users = new_users(months_ago, repeats: 2)

    # content
    period_posts_created = posts_created(months_ago, archetype: 'regular')

    # actions
    period_flags = flagged_posts(months_ago)
  end


  private

  def all_users(months_ago)
    all_users = report.all_users do |r|
      r.months_ago months_ago
    end

    puts "ALLUSERS #{all_users}"
  end

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

  def daily_active_users(months_ago)
    daily_active_users = report.daily_active_users do |r|
      r.months_ago months_ago
    end

    puts "DAU #{daily_active_users}"
  end

  def flagged_posts(months_ago)
    flagged_posts = report.flagged_posts do |r|
      r.months_ago months_ago
    end

    puts "FLAGGED POSTS #{flagged_posts}"
  end

  def new_users(months_ago, repeats: 1)
    new_users = report.new_users do |r|
      r.months_ago months_ago
      r.repeats repeats
    end

    puts "NEW USERS #{new_users}"
  end

  def posts_created(months_ago, archetype: 'regular', exclude_topic: nil)
    posts_created = report.posts_created do |r|
      r.months_ago months_ago
      r.archetype archetype
      r.exclude_topic exclude_topic if exclude_topic
    end

    puts "POSTS CREATED #{posts_created}"
  end


  def report
    @report ||= AdminStatisticsDigest::Report.new
  end
end
