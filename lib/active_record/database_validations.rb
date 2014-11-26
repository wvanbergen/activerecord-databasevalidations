require 'active_record'
require 'active_support/i18n'
require 'active_record/database_validations/version'

require 'active_record/validations/database_constraints'
require 'active_record/validations/string_truncator'

I18n.load_path << File.dirname(__FILE__) + '/database_validations/locale/en.yml'
