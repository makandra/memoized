require 'date'
require 'timecop'
require 'memoized'
if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('2.5.3')
  require 'prop_check'
end

RSpec.configure do |config|
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end

module Memoized
  class Parameters
    def test_body
      params.map(&Parameters.method(:to_test_body)).join(" * ")
    end

    def self.to_test_body((param_type, param_name))
      case param_type
      when :req
        "#{param_name}"
      when :opt
        "#{param_name}"
      when :rest
        "#{param_name}.inject(&:*)"
      when :keyreq
        "#{param_name}"
      when :key
        "#{param_name}"
      when :keyrest
        "#{param_name}.values.inject(&:*)"
      else raise "unknown parameter type"
      end
    end

    def test_arguments
      params.map(&Parameters.method(:to_test_arguments)).join(", ")
    end

    def self.to_test_arguments((param_type, param_name))
      case param_type
      when :req
        "2"
      when :opt
        "3"
      when :rest
        "5, 5, 5"
      when :keyreq
        "#{param_name}: 7"
      when :key
        "#{param_name}: 11"
      when :keyrest
        "**{first: 13, second: 13}"
      else raise "unknown parameter type"
      end
    end

    def debug_info
      "#{@req_params.size} - #{@opt_params.size} - #{@rest_params.size} " \
        "| #{@keyreq_params.size} - #{@key_params.size} - #{@keyrest_params.size}"
    end
  end
end
