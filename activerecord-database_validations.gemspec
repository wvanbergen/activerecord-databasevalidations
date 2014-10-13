# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord/database_validations/version'

Gem::Specification.new do |spec|
  spec.name          = "activerecord-database_validations"
  spec.version       = ActiveRecord::DatabaseValidations::VERSION
  spec.authors       = ["Willem van Bergen"]
  spec.email         = ["willem@railsdoctors.com"]
  spec.summary       = %q{Add validations to your ActiveRecord models based on your database constraints.}
  spec.description   = %q{Opt-in validations for your ActiveRecord models based on your database constraints, including text field length, and NOT NULL constraints.}
  spec.homepage      = "https://github.com/wvanbergen/activerecord-database_validations"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", "~> 4"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "pg"
end
