
# def to_param(abstract_param)
#
#
# end


describe "#memoize" do
  include PropCheck
  include PropCheck::Generators
  # include PropCheck::Generators::Set
  include Memoized

  it "does not change the method's parameters" do
    forall(req: array(simple_symbol)) do |req:|

      req_params = req.map(&:to_s).uniq.map { |r| "req_#{r}"}.join(', ')

      eval(<<-RUBY)
        class MemoizedPropertyClass
          include Memoized

          def parameter_dummy(#{req_params})
            42
          end

          @old_parameters = new.method(:parameter_dummy).parameters
          memoize :parameter_dummy
          @new_parameters = new.method(:parameter_dummy).parameters
        end
      RUBY



      expect(MemoizedPropertyClass.instance_variable_get(:@new_parameters)).to eq(MemoizedPropertyClass.instance_variable_get(:@old_parameters))
    end
  end
end
