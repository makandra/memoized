All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## Unreleased

### Breaking changes

- Remove no longer supported ruby versions (2.3.8, 2.4.5)

### Compatible changes

-


## 1.0.1 - 2019-02-27

### Compatible changes

- Fix meta information in gemspec.


## 1.0.0 - 2019-02-27

### Compatible changes

Forked [memoizer](https://github.com/wegowise/memoizer) with two changes:

1. Memoized methods now preserve their [arity](https://apidock.com/ruby/Method/arity). Previously all memoized methods had an arity of `-1`.
2. Memoized methods are now faster at runtime. This will only be noticable if you call a memoized methods many times in the same request.

We published our fork as a new gem named [memoized](https://rubygems.org/gems/memoized).

memoized is API-compatible to memoizer, you just need to `include Memoized` instead of `Memoizer`:

```ruby
class A
  include Memoized

  memoize def hello
    'hello!'
  end
end
```
