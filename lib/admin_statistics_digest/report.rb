require_relative './active_user'
require_relative './post_read'
require_relative './active_daily_user'
require_relative './post_made'
require_relative './new_user'
require_relative './user_visit'

class AdminStatisticsDigest::Report

  REPORTS = {
    active_users: AdminStatisticsDigest::ActiveUser,
    posts_read: AdminStatisticsDigest::PostRead,
    active_daily_users: AdminStatisticsDigest::ActiveDailyUser,
    posts_made: AdminStatisticsDigest::PostMade,
    new_users: AdminStatisticsDigest::NewUser,
    user_visits: AdminStatisticsDigest::UserVisit,
  }.freeze

  def self.generate(&block)
    self.new(&block)
  end

  def initialize(&block)
    self.rows = []

    instance_eval(&block) if block_given?
  end

  REPORTS.each do |method_name, klass_name|

    define_method(method_name.to_sym) do |&block|
      report = klass_name.new
      report.instance_eval(&block)
      result = report.execute
      if result[:error]
        raise result[:error]
      else
        self.send(:rows).push(result[:data])
        result[:data]
      end
    end

  end

  def section(name, &block)
    rows << {
      name: name,
      data: AdminStatisticsDigest::Report.new(&block).data
    }
  end

  def size
    rows.size
  end

  def data
    return rows.flatten.freeze if rows.length == 1
    rows.freeze
  end

  private
  attr_accessor :rows

end
