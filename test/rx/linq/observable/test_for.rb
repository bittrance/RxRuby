require 'test_helper'

class TestObservableFor < Minitest::Test
  include Rx::MarbleTesting

  def test_array
    actual = scheduler.configure do
      Rx::Observable.for([1, 2, 3].map {|n| Rx::Observable.of(n) })
    end

    assert_msgs msgs('--(123|)'), actual
  end

  def test_argument_error_on_nil
    assert_raises(ArgumentError) do
      Rx::Observable.for(nil)
    end
  end

  def test_with_transform
    actual = scheduler.configure do
      Rx::Observable.for([1, 2, 3]) {|n| Rx::Observable.of(n) }
    end

    assert_msgs msgs('--(123|)'), actual
  end

  class ErroringEnumerable
    def initialize(err)
      @err = err
    end

    def each
      raise @err
    end
  end

  def test_with_erroring_enumerable
    actual = scheduler.configure do
      Rx::Observable.for(ErroringEnumerable.new(error))
    end

    assert_msgs msgs('--#'), actual
  end

  def test_with_erroring_transform
    actual = scheduler.configure do
      Rx::Observable.for([Rx::Observable.of(1)]) {|n| raise error }
    end

    assert_msgs msgs('--#'), actual
  end
end
