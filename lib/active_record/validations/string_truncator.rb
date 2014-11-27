module ActiveRecord
  module DatabaseValidations
    module StringTruncator
      extend ActiveSupport::Concern

      module ClassMethods
        def truncate_string(field)
          column = self.columns_hash[field.to_s]
          limit = column.limit

          if column.text? && column.collation !~ /\Autf8_/
            raise ArgumentError, "Only UTF-8 textual columns are supported."
          end

          case column.type
          when :string
            lambda do
              return if self.changes[field].nil?
              value = self[field].to_s
              if value.length > limit
                self[field] = value.slice(0, limit)
              end
            end

          when :text
            lambda do
              return if self.changes[field].nil?
              value = self[field].to_s.encode('utf-8')
              if value.bytesize > limit
                self[field] = value.mb_chars.limit(limit).to_s
              end
            end
          end
        end
      end
    end
  end
end
