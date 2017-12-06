require 'test_helper'

class TestOperatorRescueError < Minitest::Test
  include Rx::AsyncTesting
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
    @right_completing = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_completed(200)
    )
    @right_erroring = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_error(200, @err)
    )
  end

  def test_erroring_left
    res = @scheduler.configure do
      @left_erroring.rescue_error(@right_completing)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_erroring_left_with_block
    res = @scheduler.configure do
      @left_erroring.rescue_error do |err|
        @scheduler.create_cold_observable(
          on_next(100, err),
          on_completed(200)
        )
      end
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, @err),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_with_erroring_block
    res = @scheduler.configure do
      @left_erroring.rescue_error do |err|
        raise @err
      end
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_error(SUBSCRIBED + 200, @err)
    ]
    assert_messages expected, res.messages
  end

  def test_no_error
    res = @scheduler.configure do
      @left_completing.rescue_error(@right_completing)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, res.messages
  end

  def test_unsubscribes_from_erroring_left
    @scheduler.configure do
      @left_erroring.rescue_error(@right_completing)
    end

    assert_subscriptions [subscribe(200, 400)], @left_erroring.subscriptions
    assert_subscriptions [subscribe(400, 600)], @right_completing.subscriptions
  end

  def test_rescue_error_without_error
    res = @scheduler.configure do
      @left_completing.rescue_error(@right_erroring)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, res.messages
  end

  def test_unsubscribes_from_completing_left
    @scheduler.configure do
      @left_completing.rescue_error(@right_erroring)
    end

    assert_subscriptions [subscribe(200, 400)], @left_completing.subscriptions
    assert_subscriptions [], @right_erroring.subscriptions
  end

  def test_empty_source_completes
    res = @scheduler.configure do
      Rx::Observable.rescue_error()
    end
    assert_messages [on_completed(200)], res.messages
  end

  def test_observable_rescue_error
    res = @scheduler.configure do
      Rx::Observable.rescue_error(@left_erroring, @right_completing)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_accepts_enumerator
    enum = Enumerator.new do |y|
      y << @left_erroring
      y << @right_completing
    end

    res = @scheduler.configure do
      Rx::Observable.rescue_error(enum)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_erroring_enumerator
    enum = Enumerator.new do |y|
      raise @err
    end

    res = @scheduler.configure do
      Rx::Observable.rescue_error(enum)
    end

    expected = [
      on_error(SUBSCRIBED, @err)
    ]
    assert_messages expected, res.messages
  end

  def test_disposing_stops_enumeration
    erroring = @scheduler.create_cold_observable(
      on_error(100, @err)
    )
    enum = Enumerator.new do |y|
      y << erroring while true
    end

    @scheduler.configure(disposed: 400) do
      Rx::Observable.rescue_error(enum)
    end

    expected = [
      subscribe(SUBSCRIBED, SUBSCRIBED + 100),
      subscribe(SUBSCRIBED + 100, SUBSCRIBED + 200)
    ]
    assert_subscriptions expected, erroring.subscriptions
  end

    def async_observable(*messages)
      Rx::Observable.create do |observer|
        Thread.new do
          sleep 0.001
          messages.each do |m|
            m.value.accept observer
          end
        end
      end
    end

  def test_observable_rescue_error_concurrent
    sentinel_called = false
    observables = [
      async_observable(
        on_next(0, 1),
        on_error(0, @err)
      ),
      async_observable(
        *([on_next(0, 2)] * 3),
        on_completed(0)
      ),
      async_observable(
        on_error(0, @err)
      ).do { sentinel_called = true }
    ]
    Rx::Observable.rescue_error(*observables)
      .subscribe(@observer)
    await_array_length(@observer.messages, 5)
    assert_equal false, sentinel_called
    expected = [
      on_next(0, 1),
      *[on_next(0, 2)] * 3,
      on_completed(0)
    ]
    assert_messages expected, @observer.messages
  end
end
