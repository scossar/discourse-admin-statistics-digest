require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::DailyActiveUser < AdminStatisticsDigest::BaseReport
  # Todo: maybe rename (alias) this?
  provide_filter :active_range

  def initialize
    super
  end

  # Todo: maybe this only needs to return the count?
  def to_sql
    <<~SQL
WITH "user_visit_count" as (
SELECT "users"."id" as "user_id", count("users"."id") as "user_visits" FROM "users"
INNER JOIN "user_visits" ON "user_visits"."user_id" = "users"."id"
WHERE "users"."created_at" >= '#{filters.active_range.first.beginning_of_day}' AND "users"."created_at" <= '#{filters.active_range.last.end_of_day}'
AND "user_visits"."visited_at" >= '#{filters.active_range.first.beginning_of_day}' AND "user_visits"."visited_at" <= '#{filters.active_range.last.end_of_day}'
GROUP BY "users"."id"
)
SELECT "user_id", "user_visits" FROM "user_visit_count" WHERE "user_visit_count"."user_visits" > 1
    SQL
  end

end
