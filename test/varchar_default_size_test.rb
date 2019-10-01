require 'test_helper'
require 'active_record/database_validations/varchar_191'

class Varchar < ActiveRecord::Base; end

class VarcharDefaultSizeTest < Minitest::Test
  def test_field_was_created_with_191_characters
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table(:varchars, force: true, options: "CHARACTER SET utf8mb4") do |t|
        t.string :string
      end

      # This will fail if the field is more than 767 bytes.
      ActiveRecord::Migration.add_index(:varchars, :string, unique: true)
    end

    assert_match(/\Autf8mb4_/, Varchar.columns_hash['string'].collation)
    assert_equal(191, Varchar.columns_hash['string'].limit)
  end
end
