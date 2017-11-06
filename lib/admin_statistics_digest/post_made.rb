require_relative '../admin_statistics_digest/base_report'

class AdminStatisticsDigest::PostMade < AdminStatisticsDigest::BaseReport
  # Todo: rename this
  provide_filter :active_range

  def initialize
    super
  end

  def to_sql
    posts = Post.all
    posts.to_sql
  end

end
