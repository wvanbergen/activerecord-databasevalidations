# coding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("foos", force: true) do |t|
    t.string   :string,    limit: 40
    t.text     :tinytext,  limit: 255
    t.binary   :varbinary, limit: 255
    t.binary   :blob
    t.text     :text

    t.string   :not_null_string, null: false
    t.integer  :checked,         null: false, default: 0
    t.integer  :unchecked,       null: false
  end
end

class Foo < ActiveRecord::Base
  validates :string, :tinytext, :varbinary, :blob, :text, :not_null_string, :checked, database_constraints: true
end

class DatabaseConstraintsValidatorTest < Minitest::Test
  def setup
    @foo = Foo.new(not_null_string: 'test', checked: 1)
  end

  def test_validators_are_defined
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:string].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:tinytext].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:varbinary].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:blob].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:text].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:checked].first

    assert_equal [], Foo._validators[:unchecked]
  end

  def test_not_null_field_defines_presence_validator
    validator = Foo._validators[:checked].first
    subvalidators = validator.attribute_validators(:checked)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveRecord::Validations::PresenceValidator, subvalidators.first
  end

  def test_string_field_defines_length_validator
    validator = Foo._validators[:string].first
    subvalidators = validator.attribute_validators(:string)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::LengthValidator, subvalidators.first
    assert_equal 40, subvalidators.first.options[:maximum]
  end

  def test_text_field_defines_bytesize_validator
    validator = Foo._validators[:text].first
    subvalidators = validator.attribute_validators(:text)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_equal 65535, subvalidators.first.options[:maximum]
  end

  def test_blob_field_defines_bytesize_validator
    validator = Foo._validators[:blob].first
    subvalidators = validator.attribute_validators(:blob)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_equal 65535, subvalidators.first.options[:maximum]
  end

  def test_not_null_string_field_defines_length_validator_and_presence_validator
    validator = Foo._validators[:not_null_string].first
    subvalidators = validator.attribute_validators(:not_null_string)
    assert_equal 2, subvalidators.length

    assert_kind_of ActiveModel::Validations::PresenceValidator, subvalidators.first
    assert_kind_of ActiveModel::Validations::LengthValidator, subvalidators.second
    assert_equal 255, subvalidators.second.options[:maximum]
  end

  def test_not_null_columns_with_a_default_value
    assert Foo.new(not_null_string: 'test').valid?
    assert Foo.new(not_null_string: 'test', checked: 1).valid?
    refute Foo.new(not_null_string: 'test', checked: nil).valid?
  end

  def test_length_and_not_null_constraint
    @foo.not_null_string = ' ' * 256
    assert @foo.invalid?
    refute @foo.save

    assert_equal 2, @foo.errors[:not_null_string].length
    assert_equal Set["can't be blank", "is too long (maximum is 255 characters)"], Set.new(@foo.errors[:not_null_string])
  end
end
