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
      mp = Memoized::Parameters.new(parameters.uniq(&:second))

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
