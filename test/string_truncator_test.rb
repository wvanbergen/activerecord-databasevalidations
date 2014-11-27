# encoding: utf-8
require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("magical_creatures", force: true, options: "CHARACTER SET utf8mb3") do |t|
    t.string   :string,   limit: 255
    t.text     :tinytext, limit: 255
    t.text     :text
  end
end

class MagicalCreature < ActiveRecord::Base
  include ActiveRecord::DatabaseValidations::StringTruncator

  before_validation truncate_string(:string)
  before_validation truncate_string(:tinytext)
  before_validation truncate_string(:text)

  validates :string, :tinytext, database_constraints: :size
end

class StringTruncatorTest < Minitest::Test
  def test_handles_nil_gracefully
    u_nil = MagicalCreature.create!(string: 'present', tinytext: 'present')
    u_nil.string, u_nil.tinytext = nil, nil
    assert_equal ['string', 'tinytext'], u_nil.changed
    assert u_nil.valid?
  end

  def test_truncate_varchar_field_using_characters
    u1 = MagicalCreature.new(string: 'a' * 256)
    assert u1.valid?
    assert_equal 'a' * 255, u1.string

    u2 = MagicalCreature.new(string: '漢' * 256)
    assert u2.valid?
    assert_equal '漢' * 255, u2.string
  end

  def test_truncate_text_fields_using_bytes
    u1 = MagicalCreature.new(string: 'a' * 256)
    assert u1.valid?
    assert_equal 'a' * 255, u1.string

    u2 = MagicalCreature.new(tinytext: '漢' * 86)
    assert u2.valid?
    assert_equal '漢' * 85, u2.tinytext

    u3 = MagicalCreature.new(tinytext: 'ü' * 128) # note: field limit falls between the two bytes of the last character.
    assert u3.valid?
    assert_equal 'ü' * 127, u3.tinytext
  end

  def test_recoding_support_for_text_fields
    u4 = MagicalCreature.new(tinytext: ('ü' * 128).encode('ISO-8859-15'))
    assert u4.valid?
    assert_equal 'ü' * 127, u4.tinytext
    assert_equal Encoding::UTF_8, u4.tinytext.encoding
  end

  def test_knows_limits_of_standard_types
    u5 = MagicalCreature.new(text: 'a' * 65536)
    assert u5.valid?
    assert_equal 'a' * 65535, u5.text
  end
end
