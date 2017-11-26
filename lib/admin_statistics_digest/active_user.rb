require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::ActiveUser < AdminStatisticsDigest::BaseReport

  provide_filter :months_ago

  # All users, or number of users who have visited within a time period.
  def to_sql
    months_ago_filter = if filters.months_ago
                          <<~SQL
                          AND (("u"."last_seen_at", "u"."last_seen_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}'))
                          SQL
                        else
                          nil
                        end
    select_days_in_period = if filters.months_ago
                              <<~SQL
                              , EXTRACT(DAY FROM DATE '#{filters.months_ago[:period_end]}') AS "days_in_month"
                              SQL
                            else
                              nil
                            end
    <<~SQL
SELECT
count(1) AS "active_users"
#{select_days_in_period}
FROM "users" "u"
WHERE "u"."id" > 0
#{months_ago_filter}
    SQL
  end
end
