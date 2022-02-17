# Adapted from https://github.com/rails/rails/issues/19570#issuecomment-348366536
# and https://github.com/rails/rails/blob/v6.1.3.1/activemodel/lib/active_model/validations/length.rb

# Currently only supports `:maximum`
class BytesizeValidator < ActiveModel::EachValidator
  MESSAGES = { maximum: :too_long }.freeze
  CHECKS = { maximum: :<= }.freeze
  RESERVED_OPTIONS = %i[maximum too_long].freeze

  def check_validity!
    raise ArgumentError, ERROR_MESSAGE unless options.key?(:maximum)

    maximum = options[:maximum]
    return if maximum.is_a?(Integer) && maximum >= 0

    raise ArgumentError, I18n.t("validators.bytesize_validator.non_negative")
  end

  def validate_each(record, attribute, value)
    key = :maximum
    value_bytesize = value.respond_to?(:bytesize) ? value.bytesize : value.to_s.bytesize
    errors_options = options.except(*RESERVED_OPTIONS)

    check_value = options[key]
    return if value_bytesize.public_send(CHECKS[key], check_value)

    errors_options[:count] = check_value

    default_message = options[MESSAGES[key]]
    errors_options[:message] ||= default_message if default_message

    record.errors.add(attribute, MESSAGES[key], **errors_options)
  end
end
