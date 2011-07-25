# Helper module for all views.

module ApplicationHelper

  # A combination of `pluralize` and `number_with_delimiter`.
  #
  # @param [Fixnum] count The number of items. This number will be formatted.
  # @param [String] singular The string to append to the count if the count is
  #   one.
  # @param [String] plural The string to append to the count if the count is not
  #   one.

  def pluralize_with_delimiter(count, singular, plural=nil)
    t 'helpers.application.pluralize_with_delimiter.format',
      count: number_with_delimiter(count || 0),
      thing: (count == 1 ? singular : (plural || singular.pluralize))
  end
end
