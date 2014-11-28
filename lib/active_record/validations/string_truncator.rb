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
            limit = StringTruncator.mysql_textual_column_limit(column)

            case column.type
            when :string
              value = self[field].to_s
              if limit && value.length > limit
                self[field] = value.slice(0, limit)
              end

            when :text
              value = self[field].to_s
              value.encode!('utf-8') if value.encoding != Encoding::UTF_8
              if limit && value.bytesize > limit
                self[field] = value.mb_chars.limit(limit).to_s
              end
            end

            return # to make sure the callback chain doesn't halt
          end
          return method_name
        end
      end

      def self.mysql_textual_column_limit(column)
        @mysql_textual_column_limits ||= {}
        @mysql_textual_column_limits[column] ||= begin
          raise ArgumentError, "Only UTF-8 textual columns are supported." unless column.text? && column.collation =~ /\Autf8/

          column_type = column.sql_type.sub(/\(.*\z/, '').gsub(/\s/, '_').to_sym
          type_limit  = ActiveRecord::Validations::DatabaseConstraintsValidator::TYPE_LIMITS.fetch(column_type, {})
          column.limit || type_limit[:default_maximum]
        end
      end
    end
  end
end
