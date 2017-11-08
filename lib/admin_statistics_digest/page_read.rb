require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PageRead < AdminStatisticsDigest::BaseReport
  # Todo: maybe rename (alias) this?
  provide_filter :active_range

  def initialize
    super
  end

  # Todo: maybe this only needs to return the count?
  def to_sql
    posts = Post.where(created_at: filters.active_range.first..filters.active_range.last)
    posts.to_sql
  end

end
