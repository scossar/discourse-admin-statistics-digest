require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PageRead < AdminStatisticsDigest::BaseReport

  provide_filter :active_range
  provide_filter :months_ago

  def initialize
    super
  end

  # Todo: maybe this only needs to return the count?
  def to_sql
    puts "MONTHS AGO #{filters.months_ago[:from]}"
    #posts = Post.where(created_at: filters.months_ago.first..filters.months_ago.last)
    posts = Post.all
    posts.to_sql
  end

end
