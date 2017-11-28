require 'test_helper'

class TestObservableFor < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
  end

  def test_for_array
    res = @scheduler.configure do
      Rx::Observable.for([1, 2, 3].map {|n| Rx::Observable.of(n) })
    end

    expected = [
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 2),
      on_next(SUBSCRIBED, 3),
      on_completed(SUBSCRIBED)
    ]
    assert_messages expected, res.messages
  end

  def test_for_argument_error_on_nil
    assert_raises(ArgumentError) do
      Rx::Observable.for(nil)
    end
  end

  def test_for_with_transform
    res = @scheduler.configure do
      Rx::Observable.for([1, 2, 3]) {|n| Rx::Observable.of(n) }
    end

    expected = [
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 2),
      on_next(SUBSCRIBED, 3),
      on_completed(SUBSCRIBED)
    ]
    assert_messages expected, res.messages
  end

  class ErroringEnumerable
    def initialize(err)
      @err = err
    end

    def each
      raise @err
    end
  end

  def test_for_with_erroring_enumerable
    res = @scheduler.configure do
      Rx::Observable.for(ErroringEnumerable.new(@err))
    end
    assert_messages [on_error(SUBSCRIBED, @err)], res.messages
  end

  def test_for_with_erroring_transform
    res = @scheduler.configure do
      Rx::Observable.for([Rx::Observable.of(1)]) {|n| raise @err }
    end
    assert_messages [on_error(SUBSCRIBED, @err)], res.messages
  end
end
