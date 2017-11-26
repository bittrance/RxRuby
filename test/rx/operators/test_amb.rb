require 'test_helper'

class TestOperatorAmb < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
  end

  def run_amb_test(winner, left_event, right_event)
    left = @scheduler.create_cold_observable(
      left_event
    )
    right = @scheduler.create_cold_observable(
      right_event
    )
    res = @scheduler.configure do
      left.amb(right)
    end

    if winner == :left
      left_event.time += SUBSCRIBED
      assert_messages [left_event], res.messages
      assert_subscriptions [subscribe(200, 300)], left.subscriptions
      assert_subscriptions [subscribe(200, 300)], right.subscriptions
    else
      right_event.time += SUBSCRIBED
      assert_messages [right_event], res.messages
      assert_subscriptions [subscribe(200, 300)], left.subscriptions
      assert_subscriptions [subscribe(200, 300)], right.subscriptions
    end
  end

  def test_amb_left_on_next_wins
    run_amb_test(:left, on_next(100, 1), on_completed(200))
  end

  def test_amb_left_on_error_wins
    run_amb_test(:left, on_error(100, 1), on_completed(200))
  end

  def test_amb_left_on_completed_wins
    run_amb_test(:left, on_completed(100), on_next(200, 1))
  end

  def test_amb_right_on_next_wins
    run_amb_test(:right, on_error(200, 1), on_next(100, 1))
  end

  def test_amb_right_on_error_wins
    run_amb_test(:right, on_error(200, 1), on_error(100, 1))
  end

  def test_amb_right_on_completed_wins
    run_amb_test(:right, on_completed(200), on_completed(100))
  end
end

class TestConcurrencyAmb  < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @observer = Rx::TestScheduler.new.create_observer
  end

  def test_amb_concurrency
    left = async_observable(*[on_next(100, :left)] * 3)
    right = async_observable(*[on_next(100, :right)] * 3)
    left.amb(right).subscribe(@observer)
    await_array_minimum_length(@observer.messages, 3)
    types = @observer.messages.select {|m| m.value.on_next? }.map {|m| m.value.value }.uniq
    assert_equal 1, types.size # i.e. there should not be both :left and :right
  end

  def test_observable_amb_concurrency
    observables = 10.times.map { |n| async_observable(*[on_next(100, "thread-#{n}")] * 3) }
    Rx::Observable.amb(*observables).subscribe(@observer)
    await_array_minimum_length(@observer.messages, 3)
    types = @observer.messages.select {|m| m.value.on_next? }.map {|m| m.value.value }.uniq
    assert_equal 1, types.size
  end
end
