require 'memoized/parameters'

module Memoized
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  def self.safe_name(method_name)
    method_name.to_s.sub(/\?\Z/, '_query').sub(/!\Z/, '_bang').to_sym
  end

  def self.ivar_name(method_name)
    :"@_memoized_#{self.safe_name(method_name)}"
  end

  module ClassMethods
    def memoize(*method_names)
      method_names.each do |method_name|
        memoized_ivar_name = Memoized.ivar_name(method_name)
        unmemoized_method = "_unmemoized_#{method_name}"

        alias_method unmemoized_method, method_name

        arity = instance_method(unmemoized_method).arity

        if arity == 0
          module_eval(<<-RUBY)
            def #{method_name}()
              #{memoized_ivar_name} ||= [#{unmemoized_method}()]
              #{memoized_ivar_name}.first
            end
          RUBY

        elsif arity == -1
          module_eval(<<-RUBY)
            def #{method_name}(*args)
              #{memoized_ivar_name} ||= {}
              if #{memoized_ivar_name}.has_key?(args)
                #{memoized_ivar_name}[args]
              else
                #{memoized_ivar_name}[args] = #{unmemoized_method}(*args)
              end
            end
          RUBY

        elsif arity < -1
          # For Ruby methods that take a variable number of arguments,
          # Method#arity returns -n-1, where n is the number of required arguments
          required_arg_names = (1..(-arity - 1)).map { |i| "arg#{i}" }
          required_args_ruby = required_arg_names.join(', ')

          module_eval(<<-RUBY)
            def #{method_name}(#{required_args_ruby}, *optional_args)
              all_args = [#{required_args_ruby}, *optional_args]
              #{memoized_ivar_name} ||= {}
              if #{memoized_ivar_name}.has_key?(all_args)
                #{memoized_ivar_name}[all_args]
              else
                #{memoized_ivar_name}[all_args] = #{unmemoized_method}(*all_args)
              end
            end
          RUBY

        else # positive arity
          arg_names = (1..arity).map { |i| "arg#{i}" }
          args_ruby = arg_names.join(', ')

          module_eval(<<-RUBY)
            def #{method_name}(#{args_ruby})
              all_args = [#{args_ruby}]
              #{memoized_ivar_name} ||= {}
              if #{memoized_ivar_name}.has_key?(all_args)
                #{memoized_ivar_name}[all_args]
              else
                #{memoized_ivar_name}[all_args] = #{unmemoized_method}(#{args_ruby})
              end
            end
          RUBY
        end

        if self.private_method_defined?(unmemoized_method)
          private method_name
        elsif self.protected_method_defined?(unmemoized_method)
          protected method_name
        end
      end
    end
  end

  module InstanceMethods
    def unmemoize(method_name)
      self.instance_variable_set(Memoized.ivar_name(method_name), nil)
    end

    def unmemoize_all
      (methods + private_methods + protected_methods).each do |method|
        if method.to_s =~ /^_unmemoized_(.*)/
          unmemoize($1)
        end
      end
    end
  end
end
