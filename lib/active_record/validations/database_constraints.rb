require 'active_model/validations/bytesize'
require 'active_model/validations/not_null'
require 'active_model/validations/basic_multilingual_plane'

module ActiveRecord
  module Validations
    class DatabaseConstraintsValidator < ActiveModel::EachValidator
      TYPE_LIMITS = {
        char:       { validator: ActiveModel::Validations::LengthValidator },
        varchar:    { validator: ActiveModel::Validations::LengthValidator },
        varbinary:  { validator: ActiveModel::Validations::BytesizeValidator },

        tinytext:   { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 **  8 - 1 },
        text:       { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 16 - 1 },
        mediumtext: { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 24 - 1 },
        longtext:   { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 32 - 1 },

        tinyblob:   { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 **  8 - 1 },
        blob:       { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 16 - 1 },
        mediumblob: { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 24 - 1 },
        longblob:   { validator: ActiveModel::Validations::BytesizeValidator, default_maximum: 2 ** 32 - 1 },
      }

      attr_reader :constraints

      VALID_CONSTRAINTS = Set[:size, :basic_multilingual_plane, :not_null, :range]

      def initialize(options = {})
        @constraints = Set.new(Array.wrap(options[:in]) + Array.wrap(options[:with]))
        @constraint_validators = {}
        super
      end

      def check_validity!
        invalid_constraints = constraints - VALID_CONSTRAINTS

        raise ArgumentError, "You have to specify what constraints to validate for." if constraints.empty?
        raise ArgumentError, "#{invalid_constraints.map(&:inspect).join(',')} is not a valid constraint." unless invalid_constraints.empty?
      end

      def not_null_validator(klass, column)
        return unless constraints.include?(:not_null)
        return if column.null

        ActiveModel::Validations::NotNullValidator.new(attributes: [column.name.to_sym], class: klass)
      end

      def size_validator(klass, column)
        return unless constraints.include?(:size)
        return unless column.text? || column.binary?

        column_type     = column.sql_type.sub(/\(.*\z/, '').gsub(/\s/, '_').to_sym
        type_limit      = TYPE_LIMITS.fetch(column_type, {})
        validator_class = type_limit[:validator]
        maximum         = column.limit || type_limit[:default_maximum]
        encoding        = column.text? ? determine_encoding(column) : nil

        if validator_class && maximum
          validator_class.new(attributes: [column.name.to_sym], class: klass, maximum: maximum, encoding: encoding)
        end
      end

      def range_validator(klass, column)
        return unless constraints.include?(:range)
        return unless column.number?

        unsigned = column.sql_type =~ / unsigned\z/
        case column.type
        when :decimal
          args = { attributes: [column.name.to_sym], class: klass, allow_nil: true }
          args[:less_than] = maximum = 10 ** (column.precision - column.scale)
          if unsigned
            args[:greater_than_or_equal_to] = 0
          else
            args[:greater_than] = 0 - maximum
          end
          ActiveModel::Validations::NumericalityValidator.new(args)

        when :integer
          maximum = unsigned ? 1 << (column.limit * 8) : 1 << (column.limit * 8 - 1)
          minimum = unsigned ? 0 : 0 - maximum
          ActiveModel::Validations::NumericalityValidator.new(attributes: [column.name.to_sym], class: klass, greater_than_or_equal_to: minimum, less_than: maximum, allow_nil: true, only_integer: true)
        end
      end

      def basic_multilingual_plane_validator(klass, column)
        return unless constraints.include?(:basic_multilingual_plane)
        return unless column.text? && column.collation =~ /\Autf8(?:mb3)?_/
        ActiveModel::Validations::BasicMultilingualPlaneValidator.new(attributes: [column.name.to_sym], class: klass)
      end

      def attribute_validators(klass, attribute)
        @constraint_validators[attribute] ||= begin
          column = klass.columns_hash[attribute.to_s] or raise ArgumentError.new("Model #{self.class.name} does not have column #{column_name}!")

          [
            not_null_validator(klass, column),
            size_validator(klass, column),
            basic_multilingual_plane_validator(klass, column),
            range_validator(klass, column),
          ].compact
        end
      end

      def validate_each(record, attribute, value)
        attribute_validators(record.class, attribute).each do |validator|
          validator.validate_each(record, attribute, value)
        end
      end

      private

      def determine_encoding(column)
        case column.collation
          when /\Autf8/; Encoding.find('utf-8')
          else raise NotImplementedError, "Don't know how to determine the Ruby encoding for MySQL's #{column.collation} collation."
        end
      end
    end
  end
end

module ActiveModel
  module Validations
    module ClassMethods
      def validates_database_constraints_of(*attr_names)
        validates_with ActiveRecord::Validations::DatabaseConstraintsValidator, _merge_attributes(attr_names)
      end
    end
  end
end
