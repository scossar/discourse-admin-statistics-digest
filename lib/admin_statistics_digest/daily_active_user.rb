require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::DailyActiveUser < AdminStatisticsDigest::BaseReport
  provide_filter :months_ago

  def to_sql
    <<~SQL
WITH periods AS (
SELECT
months_ago,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago AS period_start,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second' AS period_end,
COALESCE(EXTRACT(DAY FROM (date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second')), 1) AS days_in_period
FROM unnest(ARRAY #{filters.months_ago}) AS months_ago
),
daily_visits AS(    
SELECT
COUNT(uv.id) AS visits,
p.months_ago,
p.days_in_period as days_in_period
FROM user_visits uv
RIGHT JOIN periods p
ON uv.visited_at >= p.period_start
AND uv.visited_at <= p.period_end
GROUP BY p.months_ago, p.days_in_period
)

SELECT
dv.months_ago,
dv.visits / dv.days_in_period AS daily_active_users
FROM daily_visits dv
ORDER BY dv.months_ago
SQL
    end
end
