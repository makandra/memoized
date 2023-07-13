# Memoized [![Tests](https://github.com/makandra/memoized/workflows/Tests/badge.svg)](https://github.com/makandra/memoized/actions)

Memoized will memoize the results of your methods. It acts much like
`ActiveSupport::Memoizable` without all of that freezing business. The API for
unmemoizing is also a bit more explicit.

## Install

```
$ gem install memoized
```

## Usage

To define a memoized instance method, use `memoize def`:

```ruby
class A
  include Memoized

  memoize def hello
    'hello!'
  end
end
```

You may also `memoize` one or more methods after they have been defined:

```ruby
class B
  include Memoized

  def hello
    'hello!'
  end

  def goodbye
    'goodbye :('
  end

  memoize :hello, :goodbye
end
```

Memoizing class methods works the same way:

```ruby
class C
  class << self
    include Memoized

    memoize def hello
      'hello!'
    end
  end
end
```


To unmemoize a specific method:

```ruby
instance = A.new
instance.hello              # the hello method is now memoized
instance.unmemoize(:hello)  # the hello method is no longer memoized
instance.hello              # the hello method is run again and re-memoized
```


To unmemoize all methods for an instance:

```ruby
instance = B.new
instance.hello          # the hello method is now memoized
instance.goodbye        # the goodbye method is now memoized
instance.unmemoize_all  # neither hello nor goodbye are memoized anymore
```

## Limitations

When you are using Memoized with default arguments or default keyword arguments, there are some edge cased you have to
keep in mind.

When you memoize a method with (keyword) arguments that have an expression as default value, you should be aware
that the expression is evaluated only once.

```ruby
memoize def print_time(time = Time.now)
  time
end

print_time
=> 2021-07-23 14:23:18 +0200

sleep(1.minute)
print_time
=> 2021-07-23 14:23:18 +0200
```

When you memoize a method with (keyword) arguments that have default values, you should be aware that Memoized
differentiates between a method call without arguments and the default values.

```ruby
def true_or_false(default = true)
  puts 'calculate value ...'
  default
end

true_or_false
calculate value ...
=> true

true_or_false
=> true

true_or_false(true)
calculate value ...
=> true
```

## Development

Development
-----------

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make
it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).

There are tests in `spec`. We only accept PRs with tests. If you create a PR, the tests will automatically run on
GitHub actions on each push. We will only merge pull requests after a green GitHub actions run.

To run tests locally for development you have multiple options:

1. Run tests against a specific Ruby version:
   - Install and switch to the Ruby version
   - Install development dependencies using `bundle install`
   - Run tests using `bundle exec rspec`

2. Run tests against all Ruby versions:
   - Install all Ruby versions mentioned in `.github/workflows/test.yml`
   - run `bin/matrix` (only supports `rbenv` for switching Ruby versions currently)

Hints:
- At the time of writing this, we only have a single Gemfile. If that isn't the case any longer,
  check the gemika README for more detailed development instructions.
- We recommend to have sufficiently new versions of bundler (> 2.3.0) and rubygems (> 3.3.0) installed for each Ruby version.
- The script `bin/matrix` will warn you, if that is not the case. For all other methods you need to ensure that yourself.

## License

See [LICENSE.txt](https://github.com/makandra/memoized/blob/master/LICENSE.txt)


## Credits

- This gem is a fork of [Memoizer](https://github.com/wegowise/memoizer) by [Wegowise](https://www.wegowise.com/).
- Changes in this fork by [makandra](https://makandra.com).
