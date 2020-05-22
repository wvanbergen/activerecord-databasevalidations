require 'rejectu/rejectu'

module ActiveModel
  module Validations
    class BasicMultilingualPlaneValidator < ActiveModel::EachValidator
      OUTSIDE_BMP = /[^\u{0}-\u{FFFF}]/

      def validate_each(record, attribute, value)
        return if value.nil?
        return if value.to_s.encoding != Encoding::UTF_8

        unless Rejectu.valid?(value.to_s)
          errors_options = options.except(:characters_outside_basic_multilingual_plane)
          default_message = options[:characters_outside_basic_multilingual_plane]
          errors_options[:message] ||= default_message if default_message
          record.errors.add(attribute, :characters_outside_basic_multilingual_plane, **errors_options)
        end
      end
    end

    module HelperMethods
      def validates_basic_multilingual_plane_of(*attr_names)
        validates_with ActiveModel::Validations::BasicMultilingualPlaneValidator, _merge_attributes(attr_names)
      end
    end
  end
end
