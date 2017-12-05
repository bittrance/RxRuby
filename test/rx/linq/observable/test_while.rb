require 'test_helper'

class TestObservableWhile < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
  end

  def test_while_condition_completes
    res = @scheduler.configure do
      i = 0
      Rx::Observable.while(
        lambda { (i += 1) <= 3 },
        Rx::Observable.just(1)
      )
    end

    expected = [
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 1),
      on_completed(SUBSCRIBED)
    ]
    assert_messages expected, res.messages
  end

  def test_while_array_completes
    res = @scheduler.configure do
      i = 0
      Rx::Observable.while(
        lambda { (i += 1) < 4 },
        Rx::Observable.just(1)
      )
    end

    expected = [
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 1),
      on_next(SUBSCRIBED, 1),
      on_completed(SUBSCRIBED)
    ]
    assert_messages expected, res.messages
  end

  def test_while_erroring_condition
    res = @scheduler.configure do
      Rx::Observable.while(
        lambda { raise @err },
        [1, 2, 3, 4].map {|n| Rx::Observable.just(n) }
      )
    end
    assert_messages [on_error(SUBSCRIBED, @err)], res.messages
  end
end
