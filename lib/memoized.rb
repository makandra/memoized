require 'memoized/parameters'

module Memoized
  class CannotMemoize < ::StandardError; end

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

        parameters = Parameters.new(instance_method(unmemoized_method).parameters)

        module_eval(<<-RUBY)
          def #{method_name}(#{parameters.signature})
            #{parameters.cache_key}

            #{memoized_ivar_name} ||= {}
            
            if #{memoized_ivar_name}.key?(cache_key)
              #{memoized_ivar_name}[cache_key]
            else
              live_result = if all_kwargs.empty?
                #{unmemoized_method}(*all_args)
              else  
                #{unmemoized_method}(*all_args, **all_kwargs)
              end
              #{memoized_ivar_name}[cache_key] = live_result
              live_result
            end
          end
        RUBY

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
