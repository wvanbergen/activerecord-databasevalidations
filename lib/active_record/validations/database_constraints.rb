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

      attr_reader :klass, :constraints

      VALID_CONSTRAINTS = Set[:size, :basic_multilingual_plane, :not_null]

      def initialize(options = {})
        @klass = options[:class]
        @constraints = Set.new(options[:in] || Array.wrap(options[:with]))
        @constraint_validators = {}
        super
      end

      def check_validity!
        invalid_constraints = constraints - VALID_CONSTRAINTS

        raise ArgumentError, "You have to specify what constraints to validate for." if @constraints.empty?
        raise ArgumentError, "#{invalid_constraints.map(&:inspect).join(',')} is not a valid constraint." unless invalid_constraints.empty?
      end

      def not_null_validator(column)
        return unless constraints.include?(:not_null)
        return if column.null

        ActiveModel::Validations::NotNullValidator.new(attributes: [column.name.to_sym], class: klass)
      end

      def size_validator(column)
        return unless constraints.include?(:size)
        return unless column.text? || column.binary?

        column_type     = column.sql_type.sub(/\(.*\z/, '').gsub(/\s/, '_').to_sym
        type_limit      = TYPE_LIMITS.fetch(column_type, {})
        validator_class = type_limit[:validator]
        maximum         = column.limit || type_limit[:default_maximum]

        if validator_class && maximum
          validator_class.new(attributes: [column.name.to_sym], class: klass, maximum: maximum)
        end
      end

      def basic_multilingual_plane_validator(column)
        return unless constraints.include?(:basic_multilingual_plane)
        return unless column.text? && column.collation =~ /\Autf8(?:mb3)?_/
        ActiveModel::Validations::BasicMultilingualPlaneValidator.new(attributes: [column.name.to_sym], class: klass)
      end

      def attribute_validators(attribute)
        @constraint_validators[attribute] ||= begin
          column = klass.columns_hash[attribute.to_s] or raise ArgumentError.new("Model #{self.class.name} does not have column #{column_name}!")

          [
            not_null_validator(column),
            size_validator(column),
            basic_multilingual_plane_validator(column),
          ].compact
        end
      end

      def validate_each(record, attribute, value)
        attribute_validators(attribute).each do |validator|
          validator.validate_each(record, attribute, value)
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
