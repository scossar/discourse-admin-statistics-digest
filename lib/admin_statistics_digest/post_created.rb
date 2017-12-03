require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostCreated < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :archetype
  provide_filter :exclude_topic

  def to_sql
    exclude_topic_filter = if filters.exclude_topic
                             <<~SQL
                             AND "p"."post_number" > 1
                             SQL
                           else
                             nil
                           end
    <<~SQL
WITH periods AS (
SELECT
months_ago,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago AS period_start,
date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second' AS period_end,
COALESCE(EXTRACT(DAY FROM (date_trunc('month', CURRENT_DATE) - INTERVAL '1 months' * months_ago + INTERVAL '1 month' - INTERVAL '1 second')), 1) AS days_in_period
FROM unnest(ARRAY #{filters.months_ago}) AS months_ago
)

SELECT
pd.months_ago,
count(p.id) AS posts_count
FROM posts p
JOIN periods pd
ON p.created_at >= pd.period_start
AND p.created_at <= pd.period_end
JOIN topics t
ON t.id = p.topic_id
WHERE t.archetype = #{filters.archetype}
AND p.user_id > 0
#{exclude_topic_filter}
GROUP BY pd.months_ago
ORDER BY pd.months_ago
    SQL
  end
end
