# ActiveRecord::DatabaseValidations [![Build Status](https://travis-ci.org/wvanbergen/activerecord-databasevalidations.svg?branch=master)](https://travis-ci.org/wvanbergen/activerecord-databasevalidations)

Add validations to your ActiveRecord models based on your database constraints.

This gem is primarily intended for MySQL databases not running in strict mode,
which can easily cause data loss. These problems are documented in
[DataLossTest](https://github.com/wvanbergen/activerecord-databasevalidations/blob/master/test/data_loss_test.rb)

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-databasevalidations'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-databasevalidations

## Usage

You can use ActiveModel's `validates` method to define what fields you want
to validate based on the database constraints.

``` ruby
class Foo < ActiveRecord::Base
  validates :boolean_field, database_constraints: :not_null
  validates :string_field, database_constraints: [:size, :basic_multilingual_plane]
  validates :decimal_field, :integer_field, database_constraints: :range
end
```

You can also use `validates_database_constraints_of`:

``` ruby
class Bar < ActiveRecord::Base
  validates_database_constraints_of :my_field, with: :size
end
```

### Available validations

You have to specify what conatrints you want to validate for. Valid values are:

- `:range` to validate the numeric range of a column based on it's type.
- `:size` to validate for the size of textual and binary columns. It will pick character
  size or bytesize based on the column's type.
- `:basic_multilingual_plane` to validate that all characters for text fields are inside
  the basic multilingual plane of unicode (unless you use the utf8mb4 character set).
- `:not_null` to validate a NOT NULL contraint.

The validations will only be created if it makes sense for the column, e.g. a `:not_null`
validation will only be added if the column has a NOT NULL constraint defined on it.

### Hand-rolling validations

You can also instantiate the validators yourself:

``` ruby
class Bar < ActiveRecord::Base
  validates :string_field, bytesize: { maximum: 255 }, basic_multilingual_plane: true
  validates :string_field, not_null: true
end
```

Note that this will create validations without inspecting the column to see if it
actually makes sense.

### Replicating MySQL's truncation behavior

Sometimes, truncated a string that goes over the column's limit is the best option, if
you don't want one field's value being too long prevent the record from saving.

You can use `truncate_string` to replicate MySQL's non-strict truncating behavior, so
you can prepare yourself for eventually turning on strict mode.


``` ruby
class Unicorn < ActiveRecord::Base
  include ActiveRecord::DatabaseValidations::StringTruncator

  before_validation truncate_string(:string_field)
  validates :string_field, database_constraints: [:size]
end
```

In this example, it will truncate the string to a size that will fit before validation,
so the subsequent size validation will now always pass.


## Contributing

1. Fork it (http://github.com/wvanbergen/activerecord-databasevalidations/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
