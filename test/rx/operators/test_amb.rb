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

  def thread_observable(side)
    Rx::Observable.create do |o|
      Thread.new do
        sleep 0.01
        3.times { o.on_next side }
        o.on_completed
      end
    end
  end

  def test_amb_concurrency
    left = thread_observable(:left)
    right = thread_observable(:right)
    mock = Rx::MockObserver.new(@scheduler)
    left.amb(right).subscribe(mock)
    await_array_minimum_length(mock.messages, 4)
    types = mock.messages.select {|m| m.value.on_next? }.map {|m| m.value.value }.uniq
    assert_equal 1, types.size # i.e. there should not be both :left and :right
  end
end
