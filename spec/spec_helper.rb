require 'date'
require 'timecop'
require 'memoized'
require 'prop_check'
require 'byebug'

RSpec.configure do |config|
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
