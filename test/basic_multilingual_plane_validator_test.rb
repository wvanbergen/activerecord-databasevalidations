# encoding: utf-8
require 'test_helper'

class BasicMultilingualPlaneValidatorTest < Minitest::Test

  class Model
    include ActiveModel::Validations

    attr_accessor :unicode
    validates :unicode, basic_multilingual_plane: true
  end

  def setup
    @model = Model.new
  end

  def test_basic_multilingual_plane_string
    @model.unicode = 'basic multilingual ünicode'
    assert @model.valid?

  end

  def test_emoji
    @model.unicode = '💩'
    assert @model.invalid?
    assert_equal ["contains characters outside Unicode's basic multilingual plane"], @model.errors[:unicode]
  end

  def test_nil
    @model.unicode = nil
    assert @model.valid?
  end

  def test_different_type
    @model.unicode = 1
    assert @model.valid?
  end

  def test_non_unicode_encoding
    @model.unicode = 'ü'.encode('ISO-8859-15')
    assert @model.valid?
  end

  def test_utf8mb3_japanese
    @model.unicode = 'これは普通なストリングです'
    assert @model.valid?
  end

  def test_utf8mb4_kanji
    @model.unicode = '𠜎𠜱𠝹𠱓𠱸𠲖𠳏𠳕𠴕𠵼𠵿𠸎𠸏𠹷'
    assert @model.invalid?
    assert_equal ["contains characters outside Unicode's basic multilingual plane"], @model.errors[:unicode]
  end
end
