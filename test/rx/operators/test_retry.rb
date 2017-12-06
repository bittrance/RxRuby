require 'test_helper'

class TestOperatorRetry < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
    @left_completing = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    @left_erroring = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_error(200, @err)
    )
  end

  def test_retries_when_left_erroring
    res = @scheduler.configure do
      @left_erroring.retry(2)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 1),
      on_error(SUBSCRIBED + 400, @err)
    ]
    assert_messages expected, res.messages
  end
  
  def test_does_not_retry_without_error
    res = @scheduler.configure do
      @left_completing.retry(2)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, res.messages
  end
  
  def retry_infinitely
    subscription = Rx::Observable.raise_error(@err)
      .retry_infinitely
      .subscribe_on(Rx::DefaultScheduler.instance)
      .subscribe(@observer)
    await_array_minimum_length(@observer.messages, 10)
    subscription.unsubscribe
    expected = ([
      on_error(SUBSCRIBED, 1)
    ] * 10).flatten
    assert_messages expected, @observer.messages.take(10)
  end
  
  def retry_infinitely_without_error
    res = @scheduler.configure do
      @left_completing.retry_infinitely
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, res.messages
  end
end