# encoding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("foos", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.string   :string,        limit: 40
    t.text     :tinytext,      limit: 255
    t.binary   :varbinary,     limit: 255
    t.binary   :blob
    t.text     :not_null_text, null: false
    t.integer  :checked,       null: false,  default: 0
    t.integer  :unchecked,     null: false
  end

  ActiveRecord::Migration.create_table("bars", force: true, options: "CHARACTER SET utf8mb4") do |t|
    t.string   :mb4_string
  end

  ActiveRecord::Migration.create_table("empties", force: true)

  ActiveRecord::Migration.create_table("nums", force: true) do |t|
    t.column :decimal,          "DECIMAL(5,2)"
    t.column :unsigned_decimal, "DECIMAL(5,2) UNSIGNED"
    t.column :tinyint,          "TINYINT"
    t.column :smallint,         "SMALLINT"
    t.column :mediumint,        "MEDIUMINT"
    t.column :int,              "INT"
    t.column :bigint,           "BIGINT"
    t.column :unsigned_int,     "INT UNSIGNED"
  end
end

class Foo < ActiveRecord::Base
  validates :string, :tinytext, :varbinary, :blob, database_constraints: :size
  validates :checked, database_constraints: :not_null
  validates :not_null_text, database_constraints: [:size, :basic_multilingual_plane]
end

class Bar < ActiveRecord::Base
  validates :mb4_string, database_constraints: :basic_multilingual_plane
end

class Empty < ActiveRecord::Base
  attr_accessor :not_a_column

  validates(:not_a_column, database_constraints: [:size])
end

class Num < ActiveRecord::Base
  validates :decimal, :unsigned_decimal, :tinyint, :smallint, :mediumint, :int, :bigint, :unsigned_int, database_constraints: :range
end

class DatabaseConstraintsValidatorTest < Minitest::Test
  include DataLossAssertions

  def test_argument_validation
    assert_raises(ArgumentError) { Bar.validates(:mb4_string, database_constraints: []) }
    assert_raises(ArgumentError) { Bar.validates(:mb4_string, database_constraints: true) }
    assert_raises(ArgumentError) { Bar.validates(:mb4_string, database_constraints: :bogus) }
    assert_raises(ArgumentError) { Bar.validates(:mb4_string, database_constraints: [:size, :bogus]) }
  end

  def test_column_validation
    exception = assert_raises(ArgumentError) { Empty.new.valid? }
    assert_equal "Model Empty does not have column not_a_column!", exception.message
  end

  def test_validators_are_defined
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:string].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:tinytext].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:varbinary].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:blob].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:checked].first
    assert_kind_of ActiveRecord::Validations::DatabaseConstraintsValidator, Foo._validators[:not_null_text].first

    assert_equal [], Foo._validators[:unchecked]
  end

  def test_not_null_field_defines_not_null_validator_if_requested
    validator = Foo._validators[:checked].first
    subvalidators = validator.attribute_validators(Foo, :checked)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NotNullValidator, subvalidators.first
  end

  def test_string_field_defines_length_validator_by_default
    validator = Foo._validators[:string].first
    subvalidators = validator.attribute_validators(Foo, :string)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::LengthValidator, subvalidators.first
    assert_equal 40, subvalidators.first.options[:maximum]
  end

  def test_blob_field_defines_bytesize_validator
    validator = Foo._validators[:blob].first
    subvalidators = validator.attribute_validators(Foo, :blob)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_equal 65535, subvalidators.first.options[:maximum]
    assert_nil subvalidators.first.encoding
  end

  def test_not_null_text_field_defines_requested_bytesize_validator_and_unicode_validator
    validator = Foo._validators[:not_null_text].first
    subvalidators = validator.attribute_validators(Foo, :not_null_text)
    assert_equal 2, subvalidators.length

    assert_kind_of ActiveModel::Validations::BytesizeValidator, subvalidators.first
    assert_kind_of ActiveModel::Validations::BasicMultilingualPlaneValidator, subvalidators.second
    assert_equal 65535, subvalidators.first.options[:maximum]
    assert_equal Encoding.find('utf-8'), subvalidators.first.encoding
  end

  def test_not_null_columns_with_a_default_value
    assert Foo.new.valid?
    assert Foo.new(checked: 1).valid?
    refute Foo.new(checked: nil).valid?
  end

  def test_should_not_create_a_validator_for_a_utf8mb4_field
    assert Bar._validators[:mb4_string].first.attribute_validators(Bar, :mb4_string).empty?
    emoji = Bar.new(mb4_string: '')
    assert emoji.valid?
    refute_data_loss emoji
  end

  def test_decimal_range
    subvalidators = Num._validators[:decimal].first.attribute_validators(Num, :decimal)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NumericalityValidator, subvalidators.first

    inside_upper_bound = Num.new(decimal: '999.99')
    assert inside_upper_bound.valid?
    refute_data_loss(inside_upper_bound)

    inside_lower_bound = Num.new(decimal: '-999.99')
    assert inside_lower_bound.valid?
    refute_data_loss(inside_lower_bound)

    outside_upper_bound = Num.new(decimal: '1000.00')
    refute outside_upper_bound.valid?
    assert_data_loss(outside_upper_bound)

    outside_lower_bound = Num.new(decimal: '-1000.00')
    refute outside_lower_bound.valid?
    assert_data_loss(outside_lower_bound)
  end

  def test_unsigned_decimal_range
    subvalidators = Num._validators[:unsigned_decimal].first.attribute_validators(Num, :unsigned_decimal)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NumericalityValidator, subvalidators.first

    inside_upper_bound = Num.new(unsigned_decimal: '999.99')
    assert inside_upper_bound.valid?
    refute_data_loss(inside_upper_bound)

    inside_lower_bound = Num.new(unsigned_decimal: '0.00')
    assert inside_lower_bound.valid?
    refute_data_loss(inside_lower_bound)

    outside_upper_bound = Num.new(unsigned_decimal: '1000.00')
    refute outside_upper_bound.valid?
    assert_data_loss(outside_upper_bound)

    outside_lower_bound = Num.new(unsigned_decimal: '-0.01')
    refute outside_lower_bound.valid?
    assert_data_loss(outside_lower_bound)
  end

  def test_integer_range
    subvalidators = Num._validators[:bigint].first.attribute_validators(Num, :bigint)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NumericalityValidator, subvalidators.first

    inside_upper_bound = Num.new(tinyint: 127)
    assert inside_upper_bound.valid?
    refute_data_loss(inside_upper_bound)

    inside_lower_bound = Num.new(smallint: -32_768)
    assert inside_lower_bound.valid?
    refute_data_loss(inside_lower_bound)

    outside_upper_bound = Num.new(mediumint: 8_388_608)
    refute outside_upper_bound.valid?
    assert_data_loss(outside_upper_bound)

    outside_lower_bound = Num.new(int: -2_147_483_649)
    refute outside_lower_bound.valid?
    assert_data_loss(outside_lower_bound)
  end

  def unsigned_integer_range
    subvalidators = Num._validators[:unsigned_int].first.attribute_validators(Num, :unsigned_int)
    assert_equal 1, subvalidators.length
    assert_kind_of ActiveModel::Validations::NumericalityValidator, subvalidators.first

    inside_upper_bound = Num.new(unsigned_int: 4_294_967_295)
    assert inside_upper_bound.valid?
    refute_data_loss(inside_upper_bound)

    inside_lower_bound = Num.new(unsigned_int: 0)
    assert inside_lower_bound.valid?
    refute_data_loss(inside_lower_bound)

    outside_upper_bound = Num.new(unsigned_int: 4_294_967_296)
    refute outside_upper_bound.valid?
    assert_data_loss(outside_upper_bound)

    outside_lower_bound = Num.new(unsigned_int: -1)
    refute outside_lower_bound.valid?
    assert_data_loss(outside_lower_bound)
  end

  def test_error_messages
    foo = Foo.new(string: 'ü' * 41, checked: nil, not_null_text: '')
    refute foo.save

    assert_equal ["is too long (maximum is 40 characters)"], foo.errors[:string]
    assert_equal ["must be set"], foo.errors[:checked]
    assert_equal ["contains characters outside Unicode's basic multilingual plane"], foo.errors[:not_null_text]
  end

  def test_encoding_craziness
    foo = Foo.new(tinytext: ('ü' * 128).encode('ISO-8859-15'), string: ('ü' * 40).encode('ISO-8859-15'))
    assert foo.invalid?
    assert_data_loss foo
  end
end
