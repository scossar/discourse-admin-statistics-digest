require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::DailyActiveUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
WITH "periods" AS (
SELECT
"months_ago",
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * "months_ago" AS "period_start",
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * "months_ago" + INTERVAL '1 month' - INTERVAL '1 second' AS "period_end"
FROM unnest(ARRAY #{filters.months_ago}) as "months_ago"
),
"daily_visits" AS(    
SELECT
count(1) AS "visits",
"p"."months_ago",
"p"."period_end"
FROM "user_visits" "uv"
JOIN "periods" "p"
ON "uv"."visited_at" >= "p"."period_start"
AND "uv"."visited_at" <= "p"."period_end"
GROUP BY "p"."months_ago", "p"."period_end"
ORDER BY "p"."months_ago"
)

SELECT
"dv"."months_ago",
sum("dv"."visits") AS "daily_visits",
"dv"."period_end"
FROM "daily_visits" "dv"
GROUP BY "dv"."months_ago", "dv"."period_end"
SQL
    end
end
