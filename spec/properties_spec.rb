
# def to_param(abstract_param)
#
#
# end

class MemoizedParameters
  attr_accessor :req_params, :opt_params, :rest_params, :keyreq_params, :key_params, :keyrest_params

  def initialize(parameters = [])
    # This constructor does not check, whether the parameters were ordered correctly
    # with respect to the Ruby language specification. However, all outputs will be sorted correctly.
    clear_params
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
      else raise "unknown parameter type"
      end
    end
  end

  def clear_params
    @req_params = []
    @opt_params = []
    @rest_params = []
    @keyreq_params = []
    @key_params = []
    @keyrest_params = []
  end

  def params
    @req_params + @opt_params + @rest_params + @keyreq_params + @key_params + @keyrest_params
  end

  def signature
    params.map(&MemoizedParameters.method(:to_signature)).join(', ')
  end

  def self.to_signature((param_type, param_name))
    case param_type
    when :req
      "#{param_name}"
    when :opt
      "#{param_name} = 42"
    when :rest
      "*#{param_name}"
    when :keyreq
      "#{param_name}:"
    when :key
      "#{param_name}: 42"
    when :keyrest
      "**#{param_name}"
    else raise "unknown parameter type"
    end
  end

  def cache_key
    params.map(&MemoizedParameters.method(:to_cache_key)).join("\n")
  end

  def self.to_cache_key((param_type, param_name))
    case param_type
    when :req
      "all_args.push(#{param_name})"
    when :opt
      "all_args.push(#{param_name}) unless #{param_name}.equal?(42)"
    when :rest
      "all_args.push(*#{param_name})"
    when :keyreq
      "all_kwargs[:#{param_name}] = #{param_name}"
    when :key
      "all_kwargs[:#{param_name}] = #{param_name} unless #{param_name}.equal?(42)"
    when :keyrest
      "all_kwargs.merge!(#{param_name})"
    else raise "unknown parameter type"
    end
  end

end


describe "#memoize" do
  include PropCheck
  include PropCheck::Generators
  include Memoized

  it "does not change the method's parameters" do
    forall(
      array(
        tuple(
          one_of(
            constant(:req), constant(:opt), constant(:rest), constant(:keyreq), constant(:key), constant(:keyrest)
          ),
          simple_symbol.map do |sym|
            "param_#{sym}".to_sym
          end
        )
      )
    ) do |parameters|
      # params now have proper names (no :"", no Ruby keywords) due to the .map in the generator above
      mp = MemoizedParameters.new(parameters.uniq(&:second))

      eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{mp.signature})
            42
          end

          @old_parameters = new.method(:parameter_dummy).parameters
          memoize :parameter_dummy
          @new_parameters = new.method(:parameter_dummy).parameters
        end
      RUBY

      expect(MemoizedPropertyClass.instance_variable_get(:@new_parameters))
        .to eq(MemoizedPropertyClass.instance_variable_get(:@old_parameters))
    end
  end
end
