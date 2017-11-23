require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::TopicMade < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
SELECT
count(1) AS "topics_made"
FROM "topics" "t"
WHERE ("t"."created_at", "t"."created_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
AND "t"."user_id" > 0
AND "t"."archetype" = 'regular'
    SQL
  end

end
