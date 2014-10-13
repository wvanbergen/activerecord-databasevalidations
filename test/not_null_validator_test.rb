require 'test_helper'

class NotNullValidatorTest < Minitest::Test

  class Model
    include ActiveModel::Validations

    attr_accessor :not_null_attribute
    validates :not_null_attribute, not_null: true
  end

  def setup
    @model = Model.new
  end

  def test_nil
    @model.not_null_attribute = nil
    assert @model.invalid?
    assert_equal ['must be set'], @model.errors[:not_null_attribute]
  end

  def test_blank
    @model.not_null_attribute = ''
    assert @model.valid?
  end

  def test_false
    @model.not_null_attribute = false
    assert @model.valid?
  end
end
