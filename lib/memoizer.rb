module Memoizer
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
      @memoizer_memoized_methods ||= []

      method_names.each do |method_name|
        # If the method is already memoized, don't do anything
        if @memoizer_memoized_methods.include?(method_name)
          next
        else
          @memoizer_memoized_methods << method_name
        end

        memoized_ivar_name = Memoizer.ivar_name(method_name)
        unmemoized_method = "_unmemoized_#{method_name}"

        alias_method unmemoized_method, method_name

        no_args = self.instance_method(unmemoized_method).arity == 0

        define_method method_name do |*args|

          if instance_variable_defined?(memoized_ivar_name)
            memoized_value = self.instance_variable_get(memoized_ivar_name)
          end

          # if the method takes no inputs, store the value in an array
          if no_args
            if !memoized_value.is_a?(Array)
              memoized_value = [self.send(unmemoized_method)]
              self.instance_variable_set(memoized_ivar_name, memoized_value)
            end
            memoized_value.first

          #otherwise store in a hash indexed by the arguments
          else
            if !memoized_value.is_a?(Hash)
              memoized_value = {args => self.send(unmemoized_method, *args)}
              self.instance_variable_set(memoized_ivar_name, memoized_value)
            elsif !memoized_value.has_key?(args)
              memoized_value[args] = self.send(unmemoized_method, *args)
            end
            memoized_value[args]
          end
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
      self.instance_variable_set(Memoizer.ivar_name(method_name), nil)
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
