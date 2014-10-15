# encoding: utf-8

require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("unicorns", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.string :string,   limit: 40
    t.text   :tinytext, limit: 255
    t.binary :blob
  end
end

class Unicorn < ActiveRecord::Base
  # no validations
end

class DataLossTest < Minitest::Test
  def test_strict_mode_is_disabled
    refute Unicorn.connection.show_variable(:sql_mode).include?('STRICT_ALL_TABLES')
    refute Unicorn.connection.show_variable(:sql_mode).include?('STRICT_TRANS_TABLES')
  end

  def test_bounded_string_fields_silently_loses_data_when_strict_mode_is_disabled
    fitting_string = 'ü' * 40
    assert Unicorn.columns_hash['string'].limit >= fitting_string.length
    unicorn = Unicorn.create(string: fitting_string)
    assert_equal fitting_string, unicorn.reload.string

    overflowing_string = 'ü' * 41
    assert Unicorn.columns_hash['string'].limit < overflowing_string.length
    unicorn = Unicorn.create(string: overflowing_string)
    assert unicorn.reload.string != overflowing_string 
  end

  def test_text_field_silently_loses_data_when_strict_mode_is_disabled
    fitting_tinytext = '写' * 85
    assert_equal 255, fitting_tinytext.bytesize
    unicorn = Unicorn.create(tinytext: fitting_tinytext) # <= 255, the TINYTEXT limit
    assert_equal fitting_tinytext, unicorn.reload.tinytext 

    overflowing_tinytext = 'ü' * 128
    assert_equal 256, overflowing_tinytext.bytesize # > 255, the TINYTEXT limit
    unicorn = Unicorn.create(tinytext: overflowing_tinytext)
    assert unicorn.reload.tinytext != overflowing_tinytext 
  end

  def test_binary_field_silently_loses_data_when_strict_mode_is_disabled
    fitting_blob = [].pack('x65535')
    assert_equal 65535, fitting_blob.bytesize
    unicorn = Unicorn.create(blob: fitting_blob) # <= 65535, the BLOB limit
    assert_equal fitting_blob, unicorn.reload.blob 

    overflowing_blob = [].pack('x65536')
    assert_equal 65536, overflowing_blob.bytesize # > 65535, the BLOB limit
    unicorn = Unicorn.create(blob: overflowing_blob)
    assert unicorn.reload.blob != overflowing_blob 
  end

  def test_unchecked_utf8mb3_field_silently_loses_data_when_strict_mode_is_disabled
    emoji = '💩'
    assert_equal 4, emoji.bytesize
    unicorn = Unicorn.create(string: emoji)
    assert unicorn.reload.string != emoji
  end
end
