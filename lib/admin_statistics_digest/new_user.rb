require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::NewUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago
  provide_filter :repeats


  def to_sql
    repeats_filter = if filters.repeats
                       <<~SQL
   WHERE "vc"."user_visits" >= #{filters.repeats}
SQL
                     else
                       nil
                     end

    <<~SQL
WITH "new_users" AS (
SELECT "u"."id"
FROM "users" "u"
WHERE ("u"."created_at", "u"."created_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
),
"visit_counts" AS (
SELECT
count("uv"."user_id") AS "user_visits",
"uv"."user_id"
FROM "user_visits" "uv"
WHERE ("uv"."visited_at", "uv"."visited_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
GROUP BY "uv"."user_id"
)

SELECT
count(1) as "users"
FROM "new_users" "nu"
JOIN "visit_counts" "vc"
ON "vc"."user_id" = "nu"."id"
#{repeats_filter}
    SQL
  end

end
