module ActiveModel
  module Validations
    class NotNullValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        if value.nil?
          errors_options = options.except(:must_be_set)
          default_message = options[:must_be_set]
          errors_options[:message] ||= default_message if default_message
          record.errors.add(attribute, :must_be_set, errors_options)
        end
      end
    end

    module HelperMethods
      def validates_not_null_of(*attr_names)
        validates_with ActiveModel::Validations::NotNullValidator, _merge_attributes(attr_names)
      end
    end
  end
end
