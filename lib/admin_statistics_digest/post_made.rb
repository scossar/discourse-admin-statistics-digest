require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostMade < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  def to_sql
    <<~SQL
SELECT
count(1) AS "posts_made"
FROM "posts" "p"
WHERE ("p"."created_at", "p"."created_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
AND "p"."user_id" > 0
    SQL
  end

end
