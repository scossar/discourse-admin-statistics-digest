require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::ActiveDailyUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    puts "MONTHS AGO #{filters.months_ago}"
    <<~SQL
SELECT sum("uv"."posts_read") AS "posts_read"
FROM "user_visits" "uv"
WHERE "uv"."visited_at" >= '#{filters.months_ago[:period_start]}'
AND "uv"."visited_at" <= '#{filters.months_ago[:period_end]}'
    SQL
  end

end
