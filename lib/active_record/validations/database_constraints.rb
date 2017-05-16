require 'active_model/validations/bytesize'
require 'active_model/validations/not_null'
require 'active_model/validations/basic_multilingual_plane'

module ActiveRecord
  module Validations
    class DatabaseConstraintsValidator < ActiveModel::EachValidator
      attr_reader :constraints

      VALID_CONSTRAINTS = Set[:size, :basic_multilingual_plane, :not_null, :range]

      SIZE_VALIDATORS_FOR_TYPE = {
        characters: ActiveModel::Validations::LengthValidator,
        bytes: ActiveModel::Validations::BytesizeValidator,
      }

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

        maximum, type, encoding = ActiveRecord::DatabaseValidations::MySQL.column_size_limit(column)
        validator_class = SIZE_VALIDATORS_FOR_TYPE[type]

        if validator_class && maximum
          validator_class.new(attributes: [column.name.to_sym], class: klass, maximum: maximum, encoding: encoding)
        end
      end

      def range_validator(klass, column)
        return unless constraints.include?(:range)
        return unless column.number?

        args = { attributes: [column.name.to_sym], class: klass, allow_nil: true }
        args.merge!(ActiveRecord::DatabaseValidations::MySQL.column_range(column))
        ActiveModel::Validations::NumericalityValidator.new(args)
      end

      def basic_multilingual_plane_validator(klass, column)
        return unless constraints.include?(:basic_multilingual_plane)
        return unless column.text? && column.collation =~ /\Autf8(?:mb3)?_/
        ActiveModel::Validations::BasicMultilingualPlaneValidator.new(attributes: [column.name.to_sym], class: klass)
      end

      def attribute_validators(klass, attribute)
        @constraint_validators[attribute] ||= begin
          column = klass.columns_hash[attribute.to_s] or raise ArgumentError.new("Model #{self.class.name} does not have column #{column_name}!")
          column = ActiveRecord::Validations::TypedColumn.new(column)

          [
            not_null_validator(klass, column),
            size_validator(klass, column),
            basic_multilingual_plane_validator(klass, column),
            range_validator(klass, column),
          ].compact
        end
      end

      def validate_each(record, attribute, _value)
        attribute_validators(record.class, attribute).each do |validator|
          validator.validate(record)
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
