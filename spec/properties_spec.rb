unless RUBY_VERSION == '2.5.3' || RUBY_VERSION == '3.2.0'
  describe "#memoize" do
    include PropCheck
    include PropCheck::Generators
    include Memoized

    before do
      PropCheck::Property.configure do |config|
        # CAUTION:
        # 100 (default) takes 8 seconds
        # 300 takes 11 minutes
        config.n_runs = 100
      end
    end

    it "does not change the method's arity" do
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
        unique_names = parameters.uniq { |v| v[1] }
        single_args_and_kwargs = unique_names.uniq do |v|
          if [:rest, :keyrest].include?(v[0])
            v[0]
          else
            v[1]
          end
        end

        mp = Memoized::Parameters.new(single_args_and_kwargs)
        puts mp.debug_info if ENV['DEBUG'] == 'true'

        eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{mp.signature})
            42
          end

          @old_arity = new.method(:parameter_dummy).arity
          memoize :parameter_dummy
          @new_arity = new.method(:parameter_dummy).arity

          # cleanup to get rid of warnings
          remove_method :_unmemoized_parameter_dummy
          remove_method :parameter_dummy
        end
        RUBY

        expect(MemoizedPropertyClass.instance_variable_get(:@new_arity))
          .to eq(MemoizedPropertyClass.instance_variable_get(:@old_arity))
      end
    end

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
        unique_names = parameters.uniq { |v| v[1] }
        single_args_and_kwargs = unique_names.uniq do |v|
          if [:rest, :keyrest].include?(v[0])
            v[0]
          else
            v[1]
          end
        end

        mp = Memoized::Parameters.new(single_args_and_kwargs)
        puts mp.debug_info if ENV['DEBUG'] == 'true'

        eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{mp.signature})
            42
          end

          @old_parameters = new.method(:parameter_dummy).parameters
          memoize :parameter_dummy
          @new_parameters = new.method(:parameter_dummy).parameters

          # cleanup to get rid of warnings
          remove_method :_unmemoized_parameter_dummy
          remove_method :parameter_dummy
        end
        RUBY

        expect(MemoizedPropertyClass.instance_variable_get(:@new_parameters))
          .to eq(MemoizedPropertyClass.instance_variable_get(:@old_parameters))
      end
    end

    it "does not change the method's value" do
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
        unique_names = parameters.uniq { |v| v[1] }
        single_args_and_kwargs = unique_names.uniq do |v|
          if [:rest, :keyrest].include?(v[0])
            v[0]
          else
            v[1]
          end
        end

        mp = Memoized::Parameters.new(single_args_and_kwargs)
        puts mp.debug_info if ENV['DEBUG'] == 'true'

        eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{mp.signature})
            #{mp.test_body}
          end

          @old_value = new.parameter_dummy(#{mp.test_arguments})
          memoize :parameter_dummy
          @new_value = new.parameter_dummy(#{mp.test_arguments})

          # cleanup to get rid of warnings
          remove_method :_unmemoized_parameter_dummy
          remove_method :parameter_dummy
        end
        RUBY

        expect(MemoizedPropertyClass.instance_variable_get(:@new_value))
          .to eq(MemoizedPropertyClass.instance_variable_get(:@old_value))
      end
    end

    it "computes the correct value" do
      forall(array(choose(15), min: 6, max: 6)) do |parameter_multiplicities|

        params = []

        parameter_multiplicities[0].times.with_index do |counter|
          params << [:req, "required_#{counter}".to_sym]
        end

        parameter_multiplicities[1].times.with_index do |counter|
          params << [:opt, "optional_#{counter}".to_sym]
        end

        if parameter_multiplicities[2] != 0
          params << [:rest, :args]
        end

        parameter_multiplicities[3].times.with_index do |counter|
          params << [:keyreq, "required_kw_#{counter}".to_sym]
        end

        parameter_multiplicities[4].times.with_index do |counter|
          params << [:key, "optional_kw_#{counter}".to_sym]
        end

        if parameter_multiplicities[5] != 0
          params << [:keyrest, :kwargs]
        end

        mp = Memoized::Parameters.new(params, parameter_multiplicities[2], parameter_multiplicities[5])

        puts mp.debug_info if ENV['DEBUG'] == 'true'

        eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{mp.signature})
            #{mp.test_body}
          end

          memoize :parameter_dummy
          @value = new.parameter_dummy(#{mp.test_arguments})

          # cleanup to get rid of warnings
          remove_method :_unmemoized_parameter_dummy
          remove_method :parameter_dummy
        end
        RUBY

        expected_result = [2, 3, 5, 7, 11, 13].zip(parameter_multiplicities).map do |base, exponent|
          base ** exponent
        end.inject(&:*)

        expect(MemoizedPropertyClass.instance_variable_get(:@value))
          .to eq(expected_result)
      end
    end
  end
end
