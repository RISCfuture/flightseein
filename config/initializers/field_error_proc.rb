# Change the behavior of fields with bad data. This wraps them in a span with
# data-errors attributes listing the errors. The field_with_errors.js file then
# creates the appropriate popup tooltips with the error information.

ActionView::Base.field_error_proc = Proc.new do |html, object|
  errors = Array.wrap(object.error_message).map { |error| %(data-error="#{error}") }.join(' ')
  %(<span class="field-with-errors" #{errors}>#{html}</span>).html_safe
end
