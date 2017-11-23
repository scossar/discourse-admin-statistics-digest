require_relative '../admin_statistics_digest/base_report'
# todo: rename - this is used for all tha active user queries.

class AdminStatisticsDigest::ActiveDailyUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    puts "MONTHS AGO #{filters.months_ago}"
    <<~SQL
SELECT
count(1) AS "total_visits",
EXTRACT(DAY FROM DATE '#{filters.months_ago[:period_end]}') AS "days_in_month"
FROM "user_visits" "uv"
WHERE ("uv"."visited_at", "uv"."visited_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
    SQL
  end

end
