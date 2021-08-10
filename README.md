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

There are tests in `spec`. We only accept PRs with tests. To run tests:

- Install Ruby 2.6.1
- Install development dependencies using `bundle install`
- Run tests using `bundle exec rake current_rspec`

We recommend to test large changes against multiple versions of Ruby. Supported combinations are configured in `.github/workflows/test.yml`. We provide some rake tasks to help with this:

- Install development dependencies using `bundle exec rake matrix:install`
- Run tests using `bundle exec rake matrix:spec`

Note that we have configured GitHub Actions to automatically run tests in all supported Ruby versions and dependency sets after each push. We will only merge pull requests after a green GitHub Actions run.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).

## License

See [LICENSE.txt](https://github.com/makandra/memoized/blob/master/LICENSE.txt)


## Credits

- This gem is a fork of [Memoizer](https://github.com/wegowise/memoizer) by [Wegowise](https://www.wegowise.com/).
- Changes in this fork by [makandra](https://makandra.com).
