module Memoized
  class Parameters
    UNIQUE = 42.freeze

    attr_accessor :req_params, :opt_params, :rest_params, :keyreq_params, :key_params, :keyrest_params

    def initialize(parameters = [])
      # This constructor does not check, whether the parameters were ordered correctly
      # with respect to the Ruby language specification. However, all outputs will be sorted correctly.
      @req_params = []
      @opt_params = []
      @rest_params = []
      @keyreq_params = []
      @key_params = []
      @keyrest_params = []

      parameters.each do |(param_type, param_name)|
        case param_type
        when :req
          @req_params << [param_type, param_name]
        when :opt
          @opt_params << [param_type, param_name]
        when :rest
          @rest_params << [param_type, param_name]
        when :keyreq
          @keyreq_params << [param_type, param_name]
        when :key
          @key_params << [param_type, param_name]
        when :keyrest
          @keyrest_params << [param_type, param_name]
        when :block
          raise Memoized::CannotMemoize, 'Cannot memoize a method that takes a block!'
        else
          raise Memoized::CannotMemoize, 'Unknown parameter type!'
        end
      end

      if @rest_params.size > 1 || @keyrest_params.size > 1
        raise Memoized::CannotMemoize "Multiple rest or keyrest parameters, invalid signature!"
      end
    end

    def params
      @req_params + @opt_params + @rest_params + @keyreq_params + @key_params + @keyrest_params
    end

    def signature
      params.map(&Parameters.method(:to_signature)).join(', ')
    end

    def self.to_signature((param_type, param_name))
      case param_type
      when :req
        "#{param_name}"
      when :opt
        "#{param_name} = Memoized::Parameters::UNIQUE"
      when :rest
        "*#{param_name}"
      when :keyreq
        "#{param_name}:"
      when :key
        "#{param_name}: Memoized::Parameters::UNIQUE"
      when :keyrest
        "**#{param_name}"
      else raise "unknown parameter type"
      end
    end

    def cache_key
      <<-STRING
        all_args = []
        all_kwargs = {}

        #{params.map(&Parameters.method(:to_cache_key)).join("\n")}
        
        cache_key = [all_args, all_kwargs]
      STRING
    end

    def self.to_cache_key((param_type, param_name))
      case param_type
      when :req
        "all_args.push(#{param_name})"
      when :opt
        "all_args.push(#{param_name}) unless #{param_name}.equal?(Memoized::Parameters::UNIQUE)"
      when :rest
        "all_args.push(*#{param_name})"
      when :keyreq
        "all_kwargs[:#{param_name}] = #{param_name}"
      when :key
        "all_kwargs[:#{param_name}] = #{param_name} unless #{param_name}.equal?(Memoized::Parameters::UNIQUE)"
      when :keyrest
        "all_kwargs.merge!(#{param_name})"
      else raise "unknown parameter type"
      end
    end
  end
end
