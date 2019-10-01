# encoding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("unicorns", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.column :string,           "VARCHAR(40)"
    t.column :tinytext,         "TINYTEXT"
    t.column :blob,             "BLOB"

    t.column :decimal,          "DECIMAL(10, 2)"
    t.column :unsigned_decimal, "DECIMAL(5, 3) UNSIGNED"

    t.column :tinyint,          "TINYINT"
    t.column :smallint,         "SMALLINT"
    t.column :mediumint,        "MEDIUMINT"
    t.column :int,              "INT"
    t.column :bigint,           "BIGINT"
    t.column :unsigned_tinyint, "TINYINT UNSIGNED"
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
    maximum = BigDecimal(10 **  (Unicorn.columns_hash['decimal'].precision - Unicorn.columns_hash['decimal'].scale))
    delta   = BigDecimal(10 ** -(Unicorn.columns_hash['decimal'].scale), Unicorn.columns_hash['decimal'].precision)

    refute_data_loss Unicorn.new(decimal: maximum - delta)
    assert_data_loss Unicorn.new(decimal: maximum)
    refute_data_loss Unicorn.new(decimal: 0 - maximum + delta)
    assert_data_loss Unicorn.new(decimal: 0 - maximum)


    maximum = BigDecimal(10 **  (Unicorn.columns_hash['unsigned_decimal'].precision - Unicorn.columns_hash['unsigned_decimal'].scale))
    delta   = BigDecimal(10 ** -(Unicorn.columns_hash['unsigned_decimal'].scale), Unicorn.columns_hash['unsigned_decimal'].precision)

    refute_data_loss Unicorn.new(unsigned_decimal: maximum - delta)
    assert_data_loss Unicorn.new(unsigned_decimal: maximum)
    refute_data_loss Unicorn.new(unsigned_decimal: 0)
    assert_data_loss Unicorn.new(unsigned_decimal: 0 - delta)
  end

  def test_integers_silently_change_value_outside_of_range
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

    refute_data_loss Unicorn.new(unsigned_tinyint: 255)
    refute_data_loss Unicorn.new(unsigned_tinyint: 0)
    assert_data_loss Unicorn.new(unsigned_tinyint: 256)
    assert_data_loss Unicorn.new(unsigned_tinyint: -1)
  end

  def test_varchar_field_silently_drops_characters_when_over_character_limit
    refute_data_loss Unicorn.new(string: 'ü' * 40)
    assert_data_loss Unicorn.new(string: 'ü' * 41)
  end

  def test_text_field_silently_drops_charactars_when_when_over_bytesize_limit
    refute_data_loss Unicorn.new(tinytext: '写' * 85) # 85 * 3 = 255 bytes => fits
    assert_data_loss Unicorn.new(tinytext: 'ü' * 128) # 128 * 2 = 256 bytes => doesn't fit :()
  end

  def test_blob_field_silently_drops_bytes_when_when_over_bytesize_limit
    refute_data_loss Unicorn.new(blob: [].pack('x65535')) # 65535 is bytesize limit of blob field
    assert_data_loss Unicorn.new(blob: [].pack('x65536'))
  end

  def test_utf8mb3_field_sliently_truncates_strings_after_first_4byte_character
    emoji = "\u{1F4A9}"
    assert_equal 1, emoji.length
    assert_equal 4, emoji.bytesize
    assert_data_loss Unicorn.new(string: emoji)
  end
end
