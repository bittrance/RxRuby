require 'test_helper'

class TestOperatorRetryInfinitely < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
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
    left = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )

    actual = @scheduler.configure { left.retry_infinitely }

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, actual.messages
  end
end
