module ActiveRecord
  module DatabaseValidations
    module StringTruncator
      extend ActiveSupport::Concern

      module ClassMethods
        def truncate_string(field)
          column = self.columns_hash[field.to_s]
          limit = column.limit

          if column.collation !~ /\Autf8_/
            raise ArgumentError, "Only UTF-8 encoded columns are supported."
          end

          case column.type
          when :string
            Proc.new { self[field] = self[field].slice(0, limit) if self.changes.key?(field.to_s) }
          when :text
            Proc.new { self[field] = self[field].encode('utf-8').mb_chars.limit(limit).to_s if self.changes.key?(field.to_s) }
          else
            raise ArgumentError, "Can only truncate textual fields"
          end
        end
      end
    end
  end
end
