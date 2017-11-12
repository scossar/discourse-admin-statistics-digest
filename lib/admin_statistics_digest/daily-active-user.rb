require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::DailyActiveUser < AdminStatisticsDigest::BaseReport
  # Todo: maybe rename (alias) this?
  provide_filter :active_range

  def initialize
    super
  end

  def to_sql
    <<~SQL
SELECT count("user_visits"."user_id") as visits
FROM "user_visits"
WHERE "user_visits"."visited_at" >= '#{filters.active_range.first.beginning_of_day}' AND "user_visits"."visited_at" <= '#{filters.active_range.last.end_of_day}'
    SQL
  end

end
