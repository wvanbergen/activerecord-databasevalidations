module ActiveRecord
  module DatabaseValidations
    module StringTruncator
      extend ActiveSupport::Concern

      module ClassMethods
        def truncate_string(field)
          column = self.columns_hash[field.to_s]
          case column.type
          when :string
            lambda do
              return if self.changes[field].nil?
              limit = StringTruncator.mysql_textual_column_limit(column)
              value = self[field].to_s
              if value.length > limit
                self[field] = value.slice(0, limit)
              end
            end

          when :text
            lambda do
              return if self.changes[field].nil?
              limit = StringTruncator.mysql_textual_column_limit(column)
              value = self[field].to_s
              value.encode!('utf-8') if value.encoding != Encoding::UTF_8
              if value.bytesize > limit
                self[field] = value.mb_chars.limit(limit).to_s
              end
            end
          end
        end
      end

      def self.mysql_textual_column_limit(column)
        @mysql_textual_column_limits ||= {}
        @mysql_textual_column_limits[column] ||= begin
          raise ArgumentError, "Only UTF-8 textual columns are supported." unless column.text? && column.collation =~ /\Autf8_/
          column.limit
        end
      end
    end
  end
end
