require 'test_helper'

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Migration.create_table("foos") do |t|
    t.string  :string,  null: false, limit: 40
    t.text    :nullable_text
    t.boolean :boolean, null: false
    t.boolean :unchecked_boolean, null: false
  end
end

class Foo < ActiveRecord::Base
  include ActiveRecord::DatabaseValidations
  validates_database_constraints_of :string, :nullable_text, :boolean
end


class DatabaseValidationsTest < Minitest::Test
  def setup
    @foo = Foo.new(string: 'test', boolean: true, nullable_text: nil, unchecked_boolean: true)
    @foo.save!
  end

  def test_not_null_constraint
    @foo.string = nil
    assert @foo.invalid?
    assert_raises(ActiveRecord::RecordInvalid) { @foo.save! }
  end

  def test_unchecked_not_null_constraint_should_be_valid_but_will_not_save
    @foo.unchecked_boolean = nil
    assert @foo.valid?
    assert_raises(ActiveRecord::StatementInvalid) { @foo.save! }
  end

  def test_length_constraint
    @foo.string = 'a' * 40
    assert @foo.valid?

    @foo.string = 'a' * 41
    assert @foo.invalid?
  end
end
