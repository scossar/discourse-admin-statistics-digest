require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PageRead < AdminStatisticsDigest::BaseReport

  provide_filter :active_range
  provide_filter :months_ago

  def initialize
    super
  end

  # puts "MONTHS AGO #{filters.months_ago[:from]}"

  def to_sql
    <<~SQL
SELECT sum("uv"."posts_read")
FROM "user_visits" "uv"
    SQL
  end

end
