require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::UserVisit < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  # All users, or number of users who have visited within a time period.
  def to_sql
    <<~SQL
SELECT
count(1) as "user_visits",
EXTRACT(DAY FROM DATE '#{filters.months_ago[:period_end]}') AS "days_in_period"
FROM "user_visits" "uv"
WHERE ("uv"."visited_at", "uv"."visited_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
    SQL
  end

end
