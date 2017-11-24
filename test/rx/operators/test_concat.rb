require 'test_helper'
require 'rx/testing/mock_observer'

class TestOperatorConcat < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = Rx::MockObserver.new(@scheduler)
    @err = RuntimeError.new
  end

  def test_concatenates_sequences
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
        on_next(200, 2),
        on_completed(300)
      ).concat(
        @scheduler.create_cold_observable(
          on_next(100, 3),
          on_next(200, 4),
          on_completed(300)
        )
      )
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 200, 2),
      on_next(SUBSCRIBED + 400, 3),
      on_next(SUBSCRIBED + 500, 4),
      on_completed(SUBSCRIBED + 300 + 300)
    ]
    assert_messages expected, res.messages
  end
  
  def test_subscribes_sequentially
    left = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    right = @scheduler.create_cold_observable(
      on_next(100, 3),
      on_completed(200)
    )
    @scheduler.configure do
      left.concat(right)
    end

    assert_subscriptions [subscribe(200, 400)], left.subscriptions
    assert_subscriptions [subscribe(400, 600)], right.subscriptions
  end

  def test_waits_for_each_observable_to_complete
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
      ).concat(
        @scheduler.create_cold_observable(
          on_next(100, 3),
          on_completed(200)
        )
      )
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1)
    ]
    assert_messages expected, res.messages
  end

  def test_concat_aborts_on_error
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
        on_error(200, @err)
      ).concat(
        @scheduler.create_cold_observable(
          on_next(100, 3),
          on_completed(200)
        )
      )
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_error(SUBSCRIBED + 200, @err)
    ]
    assert_messages expected, res.messages
  end

  def test_does_not_subscribe_right_on_previous_error
    left = @scheduler.create_cold_observable(
      on_error(100, @err)
    )
    right = @scheduler.create_cold_observable(
      on_next(100, 3),
      on_completed(200)
    )
    @scheduler.configure do
      left.concat(right)
    end

    assert_subscriptions [], right.subscriptions
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

  def test_observable_concat_concurrency
    observables = 3.times.map {|n| thread_observable("thread-#{n}") }
    mock = Rx::MockObserver.new(@scheduler)
    Rx::Observable.concat(*observables).subscribe(mock)
    await_array_length mock.messages, 10
    expected = [
      *([on_next(0, 'thread-0')] * 3),
      *([on_next(0, 'thread-1')] * 3),
      *([on_next(0, 'thread-2')] * 3),
      on_completed(0)
    ]
    assert_messages expected, mock.messages
  end
end
