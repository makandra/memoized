require 'date'
require 'timecop'
require 'memoized'
unless RUBY_VERSION == '2.5.3'
  require 'prop_check'
end
require 'byebug'

RSpec.configure do |config|
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
