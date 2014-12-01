module ActiveRecord
  module DatabaseValidations
    module StringTruncator
      extend ActiveSupport::Concern

      module ClassMethods
        def truncate_string(field)
          method_name = :"truncate_#{field}_at_database_limit"
          define_method(method_name) do
            return unless self.changes.key?(field.to_s)
            return if self[field].nil?

            column = self.class.columns_hash[field.to_s]
            maximum, type, encoding = ActiveRecord::DatabaseValidations::MySQL.column_size_limit(column)
            value = ActiveRecord::DatabaseValidations::MySQL.value_for_column(self[field], encoding)

            case type
            when :characters
              self[field] = value.slice(0, maximum) if maximum && value.length > maximum
            when :bytes
              self[field] = value.mb_chars.limit(maximum).to_s if maximum && value.bytesize > maximum
            end

            return # to make sure the callback chain doesn't halt
          end
          return method_name
        end
      end
    end
  end
end
