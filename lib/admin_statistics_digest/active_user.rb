require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::ActiveUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
WITH "visiting_users" AS (
SELECT
count(1) as "visit"
FROM "user_visits" "uv"
WHERE "uv"."visited_at" >= '#{filters.months_ago[:period_start]}'
AND "uv"."visited_at" <= '#{filters.months_ago[:period_end]}'
GROUP BY "uv"."user_id"
)

SELECT
count(1) as "active_users"
FROM "visiting_users"
SQL
  end
end
