# coding: utf-8
lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "minitest/autorun"
require "minitest/pride"

require "yaml"

require "active_record/database_validations"

Minitest::Test = MiniTest::Unit::TestCase unless defined?(MiniTest::Test)

database_yml = YAML.load_file(File.expand_path('../database.yml', __FILE__))
ActiveRecord::Base.establish_connection(database_yml['test'])
I18n.enforce_available_locales = false
