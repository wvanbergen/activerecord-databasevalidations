lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "minitest/autorun"
require "minitest/pride"

require "yaml"

require "activerecord/database_validations"

database_yml = YAML.load_file(File.expand_path('../database.yml', __FILE__))
ActiveRecord::Base.establish_connection(database_yml[ENV['DATABASE_ADAPTER'] || 'sqlite3'])
