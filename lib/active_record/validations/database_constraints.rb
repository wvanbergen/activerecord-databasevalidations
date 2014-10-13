require 'active_model/validations/bytesize'
require 'active_model/validations/not_null'
require 'active_model/validations/basic_multilingual_plane'

module ActiveRecord
  module Validations
    class DatabaseConstraintsValidator < ActiveModel::EachValidator
      attr_reader :klass

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

      def initialize(options = {})
        @klass = options[:class]
        @constraint_validators = {}
        super
      end

      def attribute_validators(attribute)
        @constraint_validators[attribute] ||= begin
          validators = []
          column = klass.columns_hash[attribute.to_s] or raise "Model #{self.class.name} does not have column #{column_name}!"

          if !column.null
            validators << ActiveRecord::Validations::PresenceValidator.new(attributes: [attribute], class: klass)
          end

          if column.text? || column.binary?
            column_type     = column.sql_type.sub(/\(.*\z/, '').gsub(/\s/, '_').to_sym
            type_limit      = TYPE_LIMITS.fetch(column_type, {})
            validator_class = type_limit[:validator]
            maximum         = column.limit || type_limit[:default_maximum]

            if validator_class && maximum
              validators << validator_class.new(attributes: [attribute], class: klass, maximum: maximum)
            end
          end

          validators
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
