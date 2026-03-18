class MemoizedSpecClass
  include Memoized
  def no_params() Date.today; end
  def with_params?(ndays, an_array) Date.today + ndays + an_array.length; end
  def returning_nil!() Date.today; nil; end
  def all_param_types(req, opt = 3, *rest, keyreq:, key: 11, **keyrest)
    Date.today + (req * opt * rest.inject(&:*) * keyreq * key * keyrest.values.inject(&:*))
  end
  def only_kwargs(**keyrest)
    Date.today + keyrest.values.inject(&:*)
  end
  memoize :no_params, :with_params?, :returning_nil!, :all_param_types, :only_kwargs
end
class Beepbop < MemoizedSpecClass; end


describe Memoized do
  let(:today) { Date.today }

  describe '.memoize' do
    let(:object) { MemoizedSpecClass.new }
    let(:tomorrow) { Date.today + 1 }

    context "for a method with no params" do
      it "stores memoized value" do
        Timecop.freeze(today)
        expect(object.no_params).to eq(today)
        Timecop.freeze(tomorrow)
        expect(object.no_params).to eq(today)
      end
    end

    context "for a method with params (and ending in ?)" do
      it "stores memoized value" do
        Timecop.freeze(today)
        expect(object.with_params?(1, [1,2])).to eq(today + 3)
        Timecop.freeze(tomorrow)
        expect(object.with_params?(1, [1,2])).to eq(today + 3)
      end
      it "does not confuse one set of inputs for another" do
        Timecop.freeze(today)
        expect(object.with_params?(1, [1,2])).to eq(today + 3)
        expect(object.with_params?(2, [1,2])).to eq(today + 4)
        Timecop.freeze(tomorrow)
        expect(object.with_params?(1, [1,2])).to eq(today + 3)
        expect(object.with_params?(1, [2,2])).to eq(today + 4)
      end
    end

    context "for a method that returns nil (and ends in !)" do
      it "stores the memoized value" do
        object.returning_nil!
        allow(Date).to receive(:today).and_raise(ArgumentError)
        expect(object.returning_nil!).to be_nil
      end
    end

    context "for a method with all param types" do
      it "stores memoized value" do
        Timecop.freeze(today)
        expect(object.all_param_types(2, 3, 5, 5, keyreq: 7, key: 11, **{ first: 13, second: 13 })).to eq(today + 1951950)
        Timecop.freeze(tomorrow)
        expect(object.all_param_types(2, 3, 5, 5, keyreq: 7, key: 11, **{ first: 13, second: 13 })).to eq(today + 1951950)
      end
      it "does not confuse one set of inputs for another" do
        Timecop.freeze(today)
        expect(object.all_param_types(2, 3, 5, 5, keyreq: 7, key: 11, **{ first: 13, second: 13 })).to eq(today + 1951950)
        expect(object.all_param_types(2, 9, 5, keyreq: 7, key: 121, **{ first: 13 })).to eq(today + 990990)
        Timecop.freeze(tomorrow)
        expect(object.all_param_types(2, 3, 5, 5, keyreq: 7, key: 11, **{ first: 13, second: 13 })).to eq(today + 1951950)
        expect(object.all_param_types(2, 9, 5, keyreq: 7, key: 121, **{ first: 13 })).to eq(today + 990990)
      end
    end

    context "for a method with only keyword rest arguments" do
      it "stores memoized value" do
        Timecop.freeze(today)
        expect(object.only_kwargs(**{ first: 2, second: 3 })).to eq(today + 6)
        Timecop.freeze(tomorrow)
        expect(object.only_kwargs(**{ first: 2, second: 3 })).to eq(today + 6)
      end
      it "does not confuse one set of inputs for another" do
        Timecop.freeze(today)
        expect(object.only_kwargs(**{ first: 2, second: 3 })).to eq(today + 6)
        expect(object.only_kwargs(**{ first: 7 })).to eq(today + 7)
        Timecop.freeze(tomorrow)
        expect(object.only_kwargs(**{ first: 2, second: 3 })).to eq(today + 6)
        expect(object.only_kwargs(**{ first: 7 })).to eq(today + 7)
      end
    end

    context "for subclasses" do
      let(:object) { Beepbop.new }
      it "still memoizes things" do
        Timecop.freeze(today)
        expect(object.no_params).to eq(today)
        Timecop.freeze(tomorrow)
        expect(object.no_params).to eq(today)
      end
    end

    context 'for private methods' do
      class Beirut < MemoizedSpecClass
        def foo() bar; end
        private
        def bar() Date.today; end
        memoize :bar
      end
      let(:object) { Beirut.new }

      it "respects the privacy of the memoized method" do
        expect(Beirut.private_method_defined?(:bar)).to be_truthy
        expect(Beirut.private_method_defined?(:_unmemoized_bar)).to be_truthy
      end

      it "memoizes things" do
        Timecop.freeze(today)
        expect(object.foo).to eq(today)
        Timecop.freeze(today + 1)
        expect(object.foo).to eq(today)
      end
    end

    context 'for protected methods' do
      class Wonka < MemoizedSpecClass
        def foo() bar; end
        protected
        def bar() Date.today; end
        memoize :bar
      end
      let(:object) { Wonka.new }

      it "respects the privacy of the memoized method" do
        expect(Wonka.protected_method_defined?(:bar)).to be_truthy
        expect(Wonka.protected_method_defined?(:_unmemoized_bar)).to be_truthy
      end

      it "memoizes things" do
        Timecop.freeze(today)
        expect(object.foo).to eq(today)
        Timecop.freeze(today + 1)
        expect(object.foo).to eq(today)
      end
    end

    context 'for methods with an arity of 0' do
      class Arity0 < MemoizedSpecClass
        def foo()
        end

        memoize :foo
      end

      it 'creates a memoized method with an arity of 0' do
        expect(Arity0.instance_method(:foo).arity).to eq(0)
      end
    end

    context 'for methods with an arity of 2' do
      class Arity2 < MemoizedSpecClass
        def foo(a, b)
        end

        memoize :foo
      end

      it 'creates a memoized method with an arity of 2' do
        expect(Arity2.instance_method(:foo).arity).to eq(2)
      end
    end

    context 'for methods with splat args' do
      class AritySplat < MemoizedSpecClass
        def foo(*args)
        end

        memoize :foo
      end

      it 'creates a memoized method with an arity of -1' do
        expect(AritySplat.instance_method(:foo).arity).to eq(-1)
      end
    end

    context 'for methods with a required and an optional arg' do
      class ArityRequiredAndOptional < MemoizedSpecClass
        def foo(a, b = 'default')
          return [a, b]
        end

        memoize :foo
      end

      it 'creates a memoized method with a arity of -2' do
        expect(ArityRequiredAndOptional.instance_method(:foo).arity).to eq(-2)
      end

      it "preserves the optional arg's default value" do
        instance = ArityRequiredAndOptional.new
        expect(instance.foo('foo')).to eq ['foo', 'default']
      end
    end

    context 'for methods with a required arg and splat args' do
      class ArityArgAndOptional < MemoizedSpecClass
        def foo(a, *args)
          return [a, args]
        end

        memoize :foo
      end

      it 'creates a memoized method with a arity of -2' do
        expect(ArityArgAndOptional.instance_method(:foo).arity).to eq(-2)
      end

      it "passes the splat args to the memoized method" do
        instance = ArityArgAndOptional.new
        expect(instance.foo('foo', 'bar', 'baz')).to eq ['foo', ['bar', 'baz']]
      end
    end

    context 'for methods with all types of args' do
      class AllArgTypes < MemoizedSpecClass
        def foo(required, optional = 3, *rest, req_keyword:, opt_keyword: 11, **keyrest)
          return [required, optional, rest, req_keyword, opt_keyword, keyrest]
        end

        memoize :foo
      end

      it 'the memoized method has the same arity as the original method' do
        expect(AllArgTypes.instance_method(:_unmemoized_foo).arity).to eq(-3)
        expect(AllArgTypes.instance_method(:foo).arity).to eq(-3)
      end

      it 'the memoized method has the same parameters as the original method' do
        expect(AllArgTypes.instance_method(:_unmemoized_foo).parameters)
          .to eq([
            [:req, :required],
            [:opt, :optional],
            [:rest, :rest],
            [:keyreq, :req_keyword],
            [:key, :opt_keyword],
            [:keyrest, :keyrest]
          ])
        expect(AllArgTypes.instance_method(:foo).parameters)
          .to eq([
            [:req, :required],
            [:opt, :optional],
            [:rest, :rest],
            [:keyreq, :req_keyword],
            [:key, :opt_keyword],
            [:keyrest, :keyrest]
          ])
      end

      it "passes all args to the original method correctly" do
        instance = AllArgTypes.new
        expect(instance.foo(2, 333, 5, 5, req_keyword: 7, opt_keyword: 1111, first: 13, second: 17))
          .to eq [2, 333, [5, 5], 7, 1111, { first: 13, second: 17 }]
      end

      it "preserves the original method's default values" do
        instance = AllArgTypes.new
        expect(instance.foo(2, req_keyword: 7, third: 19))
          .to eq [2, 3, [], 7, 11, { third: 19 }]
      end
    end

  end

  describe '.memoize with block parameters' do
    class BlockNoArgs
      include Memoized
      def transform(&block)
        block.call("hello")
      end
      memoize :transform
    end

    class BlockWithArgs
      include Memoized
      def transform(value, &block)
        block.call(value)
      end
      memoize :transform
    end

    class BlockWithOptional
      include Memoized
      def transform(&block)
        block ? block.call("hello") : "hello"
      end
      memoize :transform
    end

    class BlockWithKwargs
      include Memoized
      def transform(prefix:, suffix: "", &block)
        result = block.call("hello")
        "#{prefix}#{result}#{suffix}"
      end
      memoize :transform
    end

    class BlockWithAllParamTypes
      include Memoized
      def transform(req, opt = ".", *rest, key:, optkey: "", **keyrest, &block)
        base = block.call(req)
        "#{base}#{opt}#{rest.join}#{key}#{optkey}#{keyrest.values.join}"
      end
      memoize :transform
    end

    class BlockPrivate
      include Memoized
      def public_transform
        transform(&:upcase)
      end
      private
      def transform(&block)
        block.call("hello")
      end
      memoize :transform
    end

    context "for a method with only a block parameter" do
      let(:object) { BlockNoArgs.new }

      it "forwards the block and caches the result" do
        result = object.transform(&:upcase)
        expect(result).to eq("HELLO")
      end

      it "returns the cached result on subsequent calls" do
        result1 = object.transform(&:upcase)
        result2 = object.transform(&:reverse)
        expect(result1).to eq("HELLO")
        expect(result2).to eq("HELLO")
      end

      it "can be unmemoized" do
        object.transform(&:upcase)
        object.unmemoize(:transform)
        result = object.transform(&:reverse)
        expect(result).to eq("olleh")
      end
    end

    context "for a method with an optional block" do
      let(:object) { BlockWithOptional.new }

      it "works when called with a block" do
        expect(object.transform(&:upcase)).to eq("HELLO")
      end

      it "works when called without a block" do
        expect(object.transform).to eq("hello")
      end

      it "returns cached result when called without a block after being cached with one" do
        object.transform(&:upcase)
        expect(object.transform).to eq("HELLO")
      end

      it "returns cached result when called with a block after being cached without one" do
        object.transform
        expect(object.transform(&:upcase)).to eq("hello")
      end
    end

    context "for a method with positional args and a block" do
      let(:object) { BlockWithArgs.new }

      it "forwards both args and block" do
        result = object.transform("world", &:upcase)
        expect(result).to eq("WORLD")
      end

      it "caches per argument, ignoring the block" do
        result1 = object.transform("world", &:upcase)
        result2 = object.transform("world", &:reverse)
        result3 = object.transform("other", &:upcase)
        expect(result1).to eq("WORLD")
        expect(result2).to eq("WORLD")
        expect(result3).to eq("OTHER")
      end
    end

    context "for a method with keyword args and a block" do
      let(:object) { BlockWithKwargs.new }

      it "forwards kwargs and block" do
        expect(object.transform(prefix: "[", suffix: "]", &:upcase)).to eq("[HELLO]")
      end

      it "caches per kwargs, ignoring the block" do
        result1 = object.transform(prefix: "[", &:upcase)
        result2 = object.transform(prefix: "[", &:reverse)
        result3 = object.transform(prefix: "(", &:upcase)
        expect(result1).to eq("[HELLO")
        expect(result2).to eq("[HELLO")
        expect(result3).to eq("(HELLO")
      end
    end

    context "for a method with all param types and a block" do
      let(:object) { BlockWithAllParamTypes.new }

      it "forwards everything and caches correctly" do
        result = object.transform("hi", "!", "a", "b", key: "k", optkey: "o", extra: "e", &:upcase)
        expect(result).to eq("HI!abkoe")
      end

      it "caches per args, ignoring the block" do
        result1 = object.transform("hi", key: "k", &:upcase)
        result2 = object.transform("hi", key: "k", &:reverse)
        expect(result1).to eq("HI.k")
        expect(result2).to eq("HI.k")
      end
    end

    context "for a private method with a block" do
      let(:object) { BlockPrivate.new }

      it "respects method visibility" do
        expect(BlockPrivate.private_method_defined?(:transform)).to be_truthy
        expect(BlockPrivate.private_method_defined?(:_unmemoized_transform)).to be_truthy
      end

      it "memoizes the private method" do
        result1 = object.public_transform
        result2 = object.public_transform
        expect(result1).to eq("HELLO")
        expect(result2).to eq("HELLO")
      end
    end
  end

  describe 'instance methods' do
    class MemoizedSpecClass
      def today() Date.today; end
      def plus_ndays(ndays) Date.today + ndays; end
      memoize :today, :plus_ndays
    end

    let(:object) { MemoizedSpecClass.new }
    before do
      Timecop.freeze(today)
      expect(object.today).to eq(today)
      expect(object.plus_ndays(1)).to eq(today + 1)
      expect(object.plus_ndays(3)).to eq(today + 3)
    end

    describe '#unmemoize' do
      context "for a method with no arguments" do
        it "clears the memoized value so it can be rememoized" do
          Timecop.freeze(today + 1)
          expect(object.today).to eq(today)

          object.unmemoize(:today)
          expect(object.today).to eq(today + 1)

          Timecop.freeze(today + 2)
          expect(object.today).to eq(today + 1)
        end
      end

      context "for a method with arguments" do
        it "unmemoizes for all inupts" do
          Timecop.freeze(today + 1)
          expect(object.plus_ndays(1)).to eq(today + 1)
          expect(object.plus_ndays(3)).to eq(today + 3)

          object.unmemoize(:plus_ndays)
          expect(object.plus_ndays(1)).to eq(today + 2)
          expect(object.plus_ndays(3)).to eq(today + 4)

          Timecop.freeze(today + 2)
          expect(object.plus_ndays(1)).to eq(today + 2)
          expect(object.plus_ndays(3)).to eq(today + 4)
        end
      end

      it "only affects the method specified" do
        Timecop.freeze(today + 1)
        expect(object.today).to eq(today)

        object.unmemoize(:plus_ndays)
        expect(object.today).to eq(today)

        object.unmemoize(:today)
        expect(object.today).to eq(today + 1)
      end

      context "for subclasses" do
        let(:object) { Beepbop.new }
        it "clears the memoized value" do
          Timecop.freeze(today + 1)
          expect(object.today).to eq(today)

          object.unmemoize(:today)
          expect(object.today).to eq(today + 1)

          Timecop.freeze(today + 2)
          expect(object.today).to eq(today + 1)
        end
      end
    end

    describe '#unmemoize_all' do
      shared_examples_for "unmemoizing methods" do
        it "clears all memoized values" do
          Timecop.freeze(today + 1)
          expect(object.today).to eq(today)
          expect(object.plus_ndays(1)).to eq(today + 1)
          expect(object.plus_ndays(3)).to eq(today + 3)

          object.unmemoize_all

          expect(object.today).to eq(today + 1)
          expect(object.plus_ndays(1)).to eq(today + 2)
          expect(object.plus_ndays(3)).to eq(today + 4)
        end
      end

      it_should_behave_like "unmemoizing methods"

      context "for subclasses" do
        let(:object) { Beepbop.new }
        it_should_behave_like "unmemoizing methods"
      end
    end

  end

end
