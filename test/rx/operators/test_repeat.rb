require 'test_helper'

class TestOperatorRepeat < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
  end

  def test_repeat
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
        on_next(200, 2),
        on_completed(300)
      ).repeat(2)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 200, 2),
      on_next(SUBSCRIBED + 400, 1),
      on_next(SUBSCRIBED + 500, 2),
      on_completed(SUBSCRIBED + 600)
    ]
    assert_messages expected, res.messages
  end

  def test_repeat_stops_with_on_error
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_error(100, @err)
      ).repeat(2)
    end
    expected = [
      on_error(SUBSCRIBED + 100, @err)
    ]
    assert_messages expected, res.messages
  end

  def test_repeat_throws_argument_error_on_bad_count
    assert_raises(ArgumentError) do
      @scheduler.create_cold_observable(
        on_completed(100)
      ).repeat(nil)
    end
  end
  
  def test_repeat_infinitely
    subscription = Rx::Observable.of(1, 2)
      .repeat_infinitely
      .subscribe_on(Rx::DefaultScheduler.instance)
      .subscribe(@observer)
    await_array_minimum_length(@observer.messages, 10)
    subscription.unsubscribe
    expected = ([
      on_next(0, 1),
      on_next(0, 2)
    ] * 5).flatten
    assert_messages expected, @observer.messages.take(10)
  end
  
  def test_repeat_infinitely_breaks_on_error
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_error(100, @err)
      ).repeat_infinitely
    end
    expected = [
      on_error(SUBSCRIBED + 100, @err)
    ]
    assert_messages expected, res.messages
  end
end