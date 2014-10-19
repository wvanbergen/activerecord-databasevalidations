# coding: utf-8
lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "minitest/autorun"
require "minitest/pride"

require "yaml"

require "active_record/database_validations"

module DataLossAssertions
  def assert_data_loss(record)
    attributes = record.changed
    provided_values = record.attributes.slice(*attributes)

    record.save!(validate: false)

    persisted_values = record.reload.attributes.slice(*attributes)
    refute_equal provided_values, persisted_values
  end

  def refute_data_loss(record)
    attributes = record.changed
    provided_values = record.attributes.slice(*attributes)

    record.save!(validate: false)

    persisted_values = record.reload.attributes.slice(*attributes)
    assert_equal provided_values, persisted_values
  end
end

Minitest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

database_yml = YAML.load_file(File.expand_path('../database.yml', __FILE__))
ActiveRecord::Base.establish_connection(database_yml['test'])
I18n.enforce_available_locales = false
