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
count(1) AS visits,
p.months_ago,
p.days_in_period as days_in_period
FROM user_visits uv
JOIN periods p
ON uv.visited_at >= p.period_start
AND uv.visited_at <= p.period_end
GROUP BY p.months_ago, p.days_in_period
ORDER BY p.months_ago
)

SELECT
dv.months_ago,
sum(dv.visits) / dv.days_in_period AS average_visits
FROM daily_visits dv
GROUP BY dv.months_ago, dv.days_in_period
SQL
    end
end
