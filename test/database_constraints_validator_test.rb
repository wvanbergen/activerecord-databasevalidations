# encoding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("foos", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.string   :string,    limit: 40
    t.text     :tinytext,  limit: 255
    t.binary   :varbinary, limit: 255
    t.binary   :blob
    t.text     :not_null_text, null: false
    t.integer  :checked,       null: false, default: 0
    t.integer  :unchecked,     null: false
  end

  ActiveRecord::Migration.create_table("bars", force: true, options: "CHARACTER SET utf8mb4") do |t|
    t.string   :mb4_string
  end
end

class Foo < ActiveRecord::Base
  validates :string, :tinytext, :varbinary, :blob, :checked, database_constraints: true
  validates :not_null_text, database_constraints: { constraints: [:size, :basic_multilingual_plane] }
end

class Bar < ActiveRecord::Base
  validates :mb4_string, database_constraints: { constraints: [:basic_multilingual_plane] }
end

class DatabaseConstraintsValidatorTest < Minitest::Test
  def test_validators_are_defined
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:string].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:tinytext].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:varbinary].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:blob].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:checked].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:not_null_text].first

    assert_equal [], Foo._validators[:unchecked]
  end

  def test_not_null_field_defines_not_null_validator_by_default
    validator = Foo._validators[:checked].first
    subvalidators = validator.attribute_validators(:checked)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NotNullValidator, subvalidators.first
  end

  def test_string_field_defines_length_validator_by_default
    validator = Foo._validators[:string].first
    subvalidators = validator.attribute_validators(:string)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::LengthValidator, subvalidators.first
    assert_equal 40, subvalidators.first.options[:maximum]
  end

  def test_blob_field_defines_bytesize_validator
    validator = Foo._validators[:blob].first
    subvalidators = validator.attribute_validators(:blob)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_equal 65535, subvalidators.first.options[:maximum]
  end

  def test_not_null_text_field_defines_requested_bytesize_validator_and_unicode_validator
    validator = Foo._validators[:not_null_text].first
    subvalidators = validator.attribute_validators(:not_null_text)
    assert_equal 2, subvalidators.length

    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_kind_of ActiveModel::Validations::BasicMultilingualPlaneValidator, subvalidators.second
    assert_equal 65535, subvalidators.first.options[:maximum]
  end

  def test_not_null_columns_with_a_default_value
    assert Foo.new.valid?
    assert Foo.new(checked: 1).valid?
    refute Foo.new(checked: nil).valid?
  end

  def test_should_not_create_a_validor_for_a_utf8mb4_field
    assert Bar.new(mb4_string: '💩').valid?
    Bar._validators[:mb4_string].first.attribute_validators(:mb4_string).empty?
  end

  def test_error_messages
    foo = Foo.new(string: 'ü' * 41, checked: nil, not_null_text: '💩')
    refute foo.save

    assert_equal ["is too long (maximum is 40 characters)"], foo.errors[:string]
    assert_equal ["must be set"], foo.errors[:checked]
    assert_equal ["contains characters outside Unicode's basic multilingual plane"], foo.errors[:not_null_text]
  end
end
