require "active_record"
require "activerecord/database_validations/version"

module ActiveRecord
  module DatabaseValidations
    extend ActiveSupport::Concern

    module ClassMethods
      def validates_database_constraints_of(*column_names)
        column_names.each do |column_name|
          column = columns_hash[column_name.to_s] or raise "Model #{self.class.name} does not have column #{column_name}!"
          
          if !column.null && !column.has_default?
            validates_with ActiveRecord::Validations::PresenceValidator, _merge_attributes([column_name])
          end

          if column.text? && column.limit.present?
            validates_with ActiveModel::Validations::LengthValidator, _merge_attributes([column_name]).merge(maximum: column.limit)
          end
        end
      end
    end
  end
end
