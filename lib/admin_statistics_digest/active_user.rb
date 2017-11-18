require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::ActiveUser < AdminStatisticsDigest::BaseReport

  provide_filter :include_staff
  provide_filter :signed_up_since
  provide_filter :signed_up_before
  provide_filter :signed_up_between
  provide_filter :active_range
  provide_filter :limit
  provide_filter :months_ago

  def initialize
    super
    filters.include_staff(false)
  end

  def to_sql
    months_ago_filter = if filters.months_ago
                                  <<~SQL
                                  AND (
                                     ("created_at", "created_at") OVERLAPS('#{filters.months_ago[:period_start]}', '#{filters.months_ago[:period_end]}')
                                   )
SQL
                                else
                                  nil
                                end
    include_staff_filter = if filters.include_staff
                             nil # include all users
                           else
                             <<~SQL
                                AND ("admin" = false AND "moderator" = false)
                             SQL
                           end

    # signed up since
    signed_up_after_filter = if filters.signed_up_between && !filters.signed_up_between[:to].present?
                               <<~SQL
                                 AND ("created_at" >= '#{filters.signed_up_between[:from]}')
                               SQL
                               else
                                 nil
                             end

    signed_up_before_filter = if filters.signed_up_before
                                <<~SQL
                                  AND ("created_at" < '#{filters.signed_up_before}')
                                SQL
                              else
                                  nil
                              end

    signed_up_between_filter = if filters.signed_up_between && filters.signed_up_between[:to].present?
                                 <<~SQL
                                   AND (
                                     ("created_at", "created_at") OVERLAPS('#{filters.signed_up_between[:from].beginning_of_day}', '#{filters.signed_up_between[:to].end_of_day}')
                                     OR DATE("created_at") = '#{filters.signed_up_between[:from]}'
                                     OR DATE("created_at") = '#{filters.signed_up_between[:to]}'
                                   )
                                 SQL
                               else
                                 nil
                               end

    topic_active_range_filter = if filters.active_range
                                <<~SQL
                                  AND (
                                    (t."created_at", t."created_at") OVERLAPS ('#{filters.active_range.first.beginning_of_day}', '#{filters.active_range.last.end_of_day}')
                                    OR DATE(t."created_at") = '#{filters.active_range.first}'
                                    OR DATE(t."created_at") = '#{filters.active_range.last}'
                                  )
                                SQL
                              else
                                nil
                              end

    reply_active_range_filter = if filters.active_range
                                <<~SQL
                                  AND (
                                    (Reply."created_at", Reply."created_at") OVERLAPS ('#{filters.active_range.first.beginning_of_day}', '#{filters.active_range.last.end_of_day}')
                                    OR DATE(Reply."created_at") = '#{filters.active_range.first}'
                                    OR DATE(Reply."created_at") =  '#{filters.active_range[:last]}'
                                  )
                                SQL
                              else
                                nil
                              end

    limit_filter = filters.limit ? "LIMIT #{filters.limit}" : nil

    sql = <<~SQL
          SELECT ut.*, count(Reply) as "replies", ut."topics" + count(Reply) AS "total" FROM "#{Post.table_name}" as Reply RIGHT JOIN (

             SELECT u.*, count(t) as "topics" FROM "#{Topic.table_name}" as t RIGHT JOIN (

                  SELECT "id" "user_id", "username", "name", EXTRACT(EPOCH FROM "created_at") "signed_up_at" from "#{User.table_name}" WHERE "id" > 0
                    #{ include_staff_filter }
                    #{ signed_up_before_filter }
                    #{ signed_up_after_filter }
                    #{ signed_up_between_filter }
                    #{ months_ago_filter }
                    ORDER BY "created_at" DESC

             ) as u ON t."user_id" = u."user_id"

             #{ topic_active_range_filter }
             #{ signed_up_after_filter }

             GROUP BY u."user_id", u."username", u."name", u."signed_up_at"
          )

          AS ut ON ut."user_id" = Reply."user_id"  AND (Reply."topic_id" IN (SELECT "id" from "topics" WHERE("topics"."archetype" = 'regular')))
          AND (Reply."deleted_at" IS NULL)
          #{ reply_active_range_filter }
          #{ signed_up_after_filter }

          GROUP BY ut."user_id", ut."username", ut."name", ut."signed_up_at", ut."topics"
          HAVING ut."topics" + count(Reply) > 0
          ORDER BY ut."topics" + COUNT(Reply) DESC, ut."signed_up_at" ASC
          #{ limit_filter }
    SQL

    sql
  end

end
