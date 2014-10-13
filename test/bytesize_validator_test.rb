# encoding: utf-8
require 'test_helper'

class BytesizeValidatorTest < Minitest::Test

  class Model
    include ActiveModel::Validations

    attr_accessor :data
    validates :data, bytesize: { maximum: 100 }
  end

  def setup
    @model = Model.new
  end

  def test_nil_is_valid
    @model.data = nil
    assert @model.valid?
  end

  def test_fitting_strings_are_valid
    @model.data = ''
    assert @model.valid?

    @model.data = 'a' * 100
    assert @model.valid?

    @model.data = 'ü' * 50
    assert @model.valid?

    @model.data = "\0" * 100
    assert @model.valid?
  end

  def test_too_large_binary_values_are_invlid
    @model.data = "\0" * 101
    assert @model.invalid?
    assert_equal ["is too long (maximum is 100 bytes)"], @model.errors[:data]
  end

  def test_too_large_unicode_values_are_invalid
    @model.data = '💩' * 26
    assert @model.invalid?
    assert_equal ["is too long (maximum is 100 bytes)"], @model.errors[:data]
  end
end
