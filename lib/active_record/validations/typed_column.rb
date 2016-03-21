# Rails 5 doesn't provide `column.number?`-ish methods.
# This delegator proxies type-related methods to superclass
# or implements them when they are not available

module ActiveRecord
  module Validations
    class TypedColumn < SimpleDelegator
      def number?
        if __getobj__.respond_to?(:number?)
          super
        else
          type == :decimal || type == :integer
        end
      end

      def text?
        if __getobj__.respond_to?(:text?)
          super
        else
          type == :text || type == :string
        end
      end

      def binary?
        if __getobj__.respond_to?(:binary?)
          super
        else
          type == :binary
        end
      end
    end
  end
end
