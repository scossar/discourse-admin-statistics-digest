require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostCreated < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
SELECT
count(1) AS "posts_created"
FROM "posts" "p"
JOIN "topics" "t"
ON "t"."id" = "p"."topic_id"
WHERE ("p"."created_at", "p"."created_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
AND "t"."archetype" = 'regular'
AND "p"."user_id" > 0
    SQL
  end
end
