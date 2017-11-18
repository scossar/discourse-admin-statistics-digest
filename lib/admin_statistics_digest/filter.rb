require 'ostruct'

class Filter
  attr_accessor :filter

  class FilterError < StandardError; end

  def initialize
    @filter = OpenStruct.new
  end

  def empty?
    filter.to_h.empty?
  end

  def months_ago(num_months = nil)
    filter[:datetime_range] = {from: num_months.month.ago.beginning_of_month, to: num_months.month.ago.end_of_month } if num_months
    filter[:datetime_range]
  end

  def datetime_range(from: nil, to: nil)
    filter[:datetime_range] = { from: from, to: to } if (from && to)
    filter[:datetime_range]
  end

  # @param [Range] date_range, Range of Date
  def active_range(date_range = nil)
    if date_range
      raise(FilterError, 'Invalid date range') if !date_range.is_a?(Range) || date_range.first > date_range.last
      filter[:date_range] = date_range
    end
    return nil if filter[:date_range].nil?
    OpenStruct.new(first: filter[:date_range].first.to_date, last: filter[:date_range].last.to_date).freeze
  end

  # @param [Integer] l
  def limit(l = nil)
    filter[:limit] = l if l
    filter[:limit]
  end

  def topic_category_id(id = nil)
    filter[:topic_category_id] = id if id
    filter[:topic_category_id]
  end

  # include Admin and Moderator user into query
  # @param [Boolean] val
  def include_staff(val = nil)
    filter[:include_staff] = val if val
    filter[:include_staff]
  end

  def signed_up_since(date = nil)
    filter[:signed_up_between] = { from: date.to_date, to: nil } if date
    filter[:signed_up_between]
  end



  def signed_up_before(date = nil)
    filter[:signed_up_before] = date.to_date if date
    filter[:signed_up_before]
  end

  def signed_up_between(from: nil, to: nil)
    filter[:signed_up_between] = { from: from.to_date, to: to.to_date} if from && to
    filter[:signed_up_between]
  end

  def filter_by_month(month = nil)
    filter[:filter_by_month] = month.beginning_of_month..month.end_of_month if month
    filter[:filter_by_month]
  end

  def filter_by_date(first_date = nil, last_date = nil)
    filter[:filter_by_month] = first_date..last_date if first_date && last_date
    filter[:filter_by_month]
  end

  alias_method :popular_by_month, :filter_by_month
  alias_method :popular_by_date, :filter_by_date

  alias_method :most_replied_by_month, :filter_by_month
  alias_method :most_replied_by_date, :filter_by_date
  private :filter_by_month

  def method_missing(method_sym, *arguments, &block)
    if filter.respond_to?(method_sym)
      begin
        filter.send(method_sym, *arguments, &block)
      rescue ArgumentError
        filter.send(method_sym)
      end
    else
      raise NoMethodError, "#{method_sym.to_s} method is undefined"
    end
  end

end
