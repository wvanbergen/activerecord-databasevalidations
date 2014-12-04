module ActiveRecord
  module DatabaseValidations
    module StringTruncator
      extend ActiveSupport::Concern

      def truncate_value_to_field_limit(field, value)
        return if value.nil?

        column = self.class.columns_hash[field.to_s]
        maximum, type, encoding = ActiveRecord::DatabaseValidations::MySQL.column_size_limit(column)
        value = ActiveRecord::DatabaseValidations::MySQL.value_for_column(value, encoding)

        case type
        when :characters
          value = value.slice(0, maximum) if maximum && value.length > maximum
        when :bytes
          value = value.mb_chars.limit(maximum).to_s if maximum && value.bytesize > maximum
        end

        value
      end

      module ClassMethods
        def truncate_to_field_limit(field)
          define_method(:"#{field}=") do |value|
            write_attribute(field, truncate_value_to_field_limit(field, value))
          end
        end

        def truncate_string(field)
          method_name = :"truncate_#{field}_at_database_limit"
          define_method(method_name) do
            return unless self.changes.key?(field.to_s)
            self[field] = truncate_value_to_field_limit(field, self[field])
            return # to make sure the callback chain doesn't halt
          end
          return method_name
        end
      end
    end
  end
end
