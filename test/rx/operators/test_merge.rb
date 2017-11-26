require 'test_helper'

class TestOperatorMerge < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = Rx::MockObserver.new(@scheduler)
    @err = RuntimeError.new
  end

  def test_merge_two_sequences_in_order_of_arrival
    left = @scheduler.create_cold_observable(
      on_next(300, 1),
      on_completed(400)
    )
    right = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_next(200, 2),
      on_next(500, 2),
      on_completed(600)
    )
    res = @scheduler.configure do
      left.merge(right)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 2),
      on_next(SUBSCRIBED + 200, 2),
      on_next(SUBSCRIBED + 300, 1),
      on_next(SUBSCRIBED + 500, 2),
      on_completed(SUBSCRIBED + 600)
    ]
    assert_messages expected, res.messages
  end

  def test_merge_no_complete_unless_all_complete
    left = @scheduler.create_cold_observable(
      on_next(300, 1),
      on_completed(400)
    )
    right = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_next(200, 2)
    )
    res = @scheduler.configure do
      left.merge(right)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 2),
      on_next(SUBSCRIBED + 200, 2),
      on_next(SUBSCRIBED + 300, 1)
    ]
    assert_messages expected, res.messages
    assert_subscriptions [subscribe(SUBSCRIBED, 1000)], right.subscriptions
  end

  def test_merge_on_error_left
    left = @scheduler.create_cold_observable(
      on_error(200, @err)
    )
    right = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_next(300, 1)
    )
    res = @scheduler.configure do
      left.merge(right)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_error(SUBSCRIBED + 200, @err)
    ]
    assert_messages expected, res.messages
    expected = [
      subscribe(SUBSCRIBED, SUBSCRIBED + 200)
    ]
    assert_subscriptions expected, right.subscriptions
  end
end
