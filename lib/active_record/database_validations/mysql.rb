module ActiveRecord
  module DatabaseValidations
    module MySQL
      TYPE_LIMITS = {
        char:       { type: :characters },
        varchar:    { type: :characters },
        varbinary:  { type: :bytes },

        tinytext:   { type: :bytes, maximum: 2 **  8 - 1 },
        text:       { type: :bytes, maximum: 2 ** 16 - 1 },
        mediumtext: { type: :bytes, maximum: 2 ** 24 - 1 },
        longtext:   { type: :bytes, maximum: 2 ** 32 - 1 },

        tinyblob:   { type: :bytes, maximum: 2 **  8 - 1 },
        blob:       { type: :bytes, maximum: 2 ** 16 - 1 },
        mediumblob: { type: :bytes, maximum: 2 ** 24 - 1 },
        longblob:   { type: :bytes, maximum: 2 ** 32 - 1 },
      }

      def self.column_size_limit(column)
        @column_size_limit ||= {}
        @column_size_limit[column] ||= begin
          column_type = column.sql_type.sub(/\(.*\z/, '').gsub(/\s/, '_').to_sym
          type_limit  = TYPE_LIMITS.fetch(column_type, {})

          [
            column.limit || type_limit[:maximum],
            type_limit[:type],
            determine_encoding(column),
          ]
        end
      end

      def self.column_range(column)
        args = {}
        unsigned = column.sql_type =~ / unsigned\z/
        case column.type
        when :decimal
          args[:less_than] = maximum = 10 ** (column.precision - column.scale)
          if unsigned
            args[:greater_than_or_equal_to] = 0
          else
            args[:greater_than] = 0 - maximum
          end

        when :integer
          args[:only_integer] = true
          args[:less_than] = unsigned ? 1 << (column.limit * 8) : 1 << (column.limit * 8 - 1)
          args[:greater_than_or_equal_to] = unsigned ? 0 : 0 - args[:less_than]
        end

        args
      end

      def self.determine_encoding(column)
        return nil unless column.text?
        case column.collation
          when /\Autf8/; Encoding::UTF_8
          else raise NotImplementedError, "Don't know how to determine the Ruby encoding for MySQL's #{column.collation} collation."
        end
      end

      def self.requires_transcoding?(value, column_encoding = nil)
        column_encoding.present? && column_encoding != value.encoding
      end

      def self.value_for_column(value, column_encoding = nil)
        value = value.to_s unless value.is_a?(String)
        value.encode!('utf-8') if requires_transcoding?(value, column_encoding)
        return value
      end
    end
  end
end
