require 'memoizer'
require 'spec_helper'

class MemoizerSpecClass
  include Memoizer
  def no_params() Date.today; end
  def with_params?(ndays, an_array) Date.today + ndays + an_array.length; end
  def returning_nil!() Date.today; nil; end
  def double_memoized() Date.today; end
  memoize :no_params, :with_params?, :returning_nil!, :double_memoized
  memoize :double_memoized
end
class Beepbop < MemoizerSpecClass; end


describe Memoizer do
  let(:today) { Date.today }

  describe '.memoize' do
    let(:object) { MemoizerSpecClass.new }
    let(:tomorrow) { Date.today + 1 }

    context "for a method with no params" do
      it "stores memoized value" do
        Timecop.freeze(today)
        expect(object.no_params).to eq(today)
        Timecop.freeze(tomorrow)
        expect(object.no_params).to eq(today)
      end
    end

    context "for a double-memoized method" do
      it "works the same as a calling memoize once" do
        Timecop.freeze(today)
        expect(object.double_memoized).to eq(today)
        Timecop.freeze(tomorrow)
        expect(object.double_memoized).to eq(today)
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
      class Beirut < MemoizerSpecClass
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
      class Wonka < MemoizerSpecClass
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

  end


  describe 'instance methods' do
    class MemoizerSpecClass
      def today() Date.today; end
      def plus_ndays(ndays) Date.today + ndays; end
      memoize :today, :plus_ndays
    end

    let(:object) { MemoizerSpecClass.new }
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
