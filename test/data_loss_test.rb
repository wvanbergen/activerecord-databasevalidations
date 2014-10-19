# encoding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("unicorns", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.string  :string,    limit: 40
    t.text    :tinytext,  limit: 255
    t.binary  :blob
    t.decimal :decimal,   precision: 10, scale: 2
    t.integer :tinyint,   limit: 1
    t.integer :smallint,  limit: 2
    t.integer :mediumint, limit: 3
    t.integer :int,       limit: 4
    t.integer :bigint,    limit: 8
  end
end

class Unicorn < ActiveRecord::Base
  # no validations
end

class DataLossTest < Minitest::Test
  include DataLossAssertions

  def test_strict_mode_is_disabled
    refute Unicorn.connection.show_variable(:sql_mode).include?('STRICT_ALL_TABLES')
    refute Unicorn.connection.show_variable(:sql_mode).include?('STRICT_TRANS_TABLES')
  end

  def test_decimal_silently_changes_out_of_bound_values
    factor = Unicorn.columns_hash['decimal'].precision - Unicorn.columns_hash['decimal'].scale

    refute_data_loss Unicorn.new(decimal: BigDecimal.new(10 ** factor - 1))
    assert_data_loss Unicorn.new(decimal: BigDecimal.new(10 ** factor))
  end

  def test_integers_loses_value_outside_of_range
    refute_data_loss Unicorn.new(tinyint:  127)
    refute_data_loss Unicorn.new(tinyint: -128)
    assert_data_loss Unicorn.new(tinyint:  128)
    assert_data_loss Unicorn.new(tinyint: -129)

    refute_data_loss Unicorn.new(smallint:  32_767)
    refute_data_loss Unicorn.new(smallint: -32_768)
    assert_data_loss Unicorn.new(smallint:  32_768)
    assert_data_loss Unicorn.new(smallint: -32_769)

    refute_data_loss Unicorn.new(mediumint:  8_388_607)
    refute_data_loss Unicorn.new(mediumint: -8_388_608)
    assert_data_loss Unicorn.new(mediumint:  8_388_608)
    assert_data_loss Unicorn.new(mediumint: -8_388_609)

    refute_data_loss Unicorn.new(int:  2_147_483_647)
    refute_data_loss Unicorn.new(int: -2_147_483_648)
    assert_data_loss Unicorn.new(int:  2_147_483_648)
    assert_data_loss Unicorn.new(int: -2_147_483_649)

    refute_data_loss Unicorn.new(bigint:  9_223_372_036_854_775_807)
    refute_data_loss Unicorn.new(bigint: -9_223_372_036_854_775_808)
    assert_data_loss Unicorn.new(bigint:  9_223_372_036_854_775_808)
    assert_data_loss Unicorn.new(bigint: -9_223_372_036_854_775_809)
  end

  def test_bounded_string_fields_silently_loses_data_when_strict_mode_is_disabled
    refute_data_loss Unicorn.new(string: 'ü' * 40)
    assert_data_loss Unicorn.new(string: 'ü' * 41)
  end

  def test_text_field_silently_loses_data_when_strict_mode_is_disabled
    refute_data_loss Unicorn.new(tinytext: '写' * 85) # 85 * 3 = 255 bytes => fits
    assert_data_loss Unicorn.new(tinytext: 'ü' * 128) # 128 * 2 = 256 bytes => doesn't fit :()
  end

  def test_binary_field_silently_loses_data_when_strict_mode_is_disabled
    refute_data_loss Unicorn.new(blob: [].pack('x65535')) # 65535 is bytesize limit of blob field
    assert_data_loss Unicorn.new(blob: [].pack('x65536'))
  end

  def test_unchecked_utf8mb3_field_silently_loses_data_when_strict_mode_is_disabled
    emoji = '💩'
    assert_equal 1, emoji.length
    assert_equal 4, emoji.bytesize
    assert_data_loss Unicorn.new(string: emoji)
  end
end
