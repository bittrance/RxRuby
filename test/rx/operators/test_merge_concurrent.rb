require 'test_helper'

class TestOperatorMergeConcurrent < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = Rx::MockObserver.new(@scheduler)
    @err = RuntimeError.new
  end

  def test_merge_three_sequences_two_at_a_time
    no1 = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    no2 = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_completed(200)
    )
    no3 = @scheduler.create_cold_observable(
      on_next(100, 3),
      on_completed(200)
    )
    no1_start, no2_start, no3_start = [50, 100, 150]

    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(no1_start, no1),
        on_next(no2_start, no2),
        on_next(no3_start, no3),
        on_completed(no3_start + 50)
      ).merge_concurrent(2)
    end

    expected = [
      on_next(SUBSCRIBED + no1_start + 100, 1),
      on_next(SUBSCRIBED + no2_start + 100, 2),
      on_next(SUBSCRIBED + no1_start + 200 + 100, 3),
      on_completed(SUBSCRIBED + no1_start + 200 + 200)
    ]
    assert_messages expected, res.messages
    expected = [
      subscribe(SUBSCRIBED + no1_start, SUBSCRIBED + no1_start + 200)
    ]
    assert_subscriptions expected, no1.subscriptions
    expected = [
      subscribe(SUBSCRIBED + no2_start, SUBSCRIBED + no2_start + 200)
    ]
    assert_subscriptions expected, no2.subscriptions
    expected = [
      subscribe(SUBSCRIBED + no1_start + 200, SUBSCRIBED + no1_start + 400)
    ]
    assert_subscriptions expected, no3.subscriptions
  end

  def test_error_stops_later_subscription
    no1 = @scheduler.create_cold_observable(
      on_completed(200)
    )
    no2 = @scheduler.create_cold_observable(
      on_error(100, @err)
    )
    no3 = @scheduler.create_cold_observable(
      on_next(150, 3),
      on_completed(200)
    )

    no1_start, no2_start, no3_start = [50, 100, 150]
    res = @scheduler.configure do
      @scheduler.create_cold_observable( # 200
        on_next(no1_start, no1), # 250, 450
        on_next(no2_start, no2), # 300, 400
        on_next(no3_start, no3), # 350, 500, 550
        on_completed(no3_start + 100), # 450
      ).merge_concurrent(2)
    end

    expected = [
      on_error(SUBSCRIBED + no2_start + 100, @err)
    ]
    assert_messages expected, res.messages
    expected = [
      subscribe(SUBSCRIBED + no1_start, SUBSCRIBED + no2_start + 100)
    ]
    assert_subscriptions expected, no1.subscriptions
    expected = [
      subscribe(SUBSCRIBED + no2_start, SUBSCRIBED + no2_start + 100)
    ]
    assert_subscriptions expected, no2.subscriptions
    assert_subscriptions [], no3.subscriptions
  end

  def test_handles_concurrency_exceeding_emissions
    no1 = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    no2 = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_completed(200)
    )

    no1_start, no2_start = [100, 200]
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(no1_start, no1),
        on_next(no2_start, no2),
        on_completed(no2_start + 300)
      ).merge_concurrent(5)
    end

    expected = [
      on_next(SUBSCRIBED + no1_start + 100, 1),
      on_next(SUBSCRIBED + no2_start + 100, 2),
      on_completed(SUBSCRIBED + no1_start + 200 + 200)
    ]
    assert_messages expected, res.messages
    expected = [
      subscribe(SUBSCRIBED + no1_start, SUBSCRIBED + no1_start + 200)
    ]
    assert_subscriptions expected, no1.subscriptions
    expected = [
      subscribe(SUBSCRIBED + no2_start, SUBSCRIBED + no2_start + 200)
    ]
    assert_subscriptions expected, no2.subscriptions
  end

  def test_handles_single_emission
    no1 = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    no1_start = 100
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(no1_start, no1),
        on_completed(200)
      ).merge_concurrent(2)
    end
    expected = [
      on_next(SUBSCRIBED + no1_start + 100, 1),
      on_completed(SUBSCRIBED + no1_start + 200)
    ]
    assert_messages expected, res.messages
    expected = [
      subscribe(SUBSCRIBED + no1_start, SUBSCRIBED + no1_start + 200)
    ]
    assert_subscriptions expected, no1.subscriptions
  end

  def test_handles_empty_stream
    no1 = @scheduler.create_cold_observable(
      on_completed(100)
    )
    @scheduler.configure do
      no1.merge_concurrent(2)
    end
    expected = [
      subscribe(SUBSCRIBED, SUBSCRIBED + 100)
    ]
    assert_subscriptions expected, no1.subscriptions
  end

  def test_fail_on_bad_concurrency
    assert_raises(ArgumentError) do
      Rx::Observable.empty.merge_concurrent(nil)
    end
  end
end

class TestObservableMergeConcurrent < Minitest::Test
  include Rx::MarbleTesting

  def test_merge_three_sequences_two_at_a_time
    a        = cold('  -1-|')
    b        = cold('  --2|')
    c        = cold('     -3|')
    expected = msgs('---12-3|')
    a_subs   = subs('--^--!')
    b_subs   = subs('--^--!')
    c_subs   = subs('-----^-!')

    actual = scheduler.configure { Rx::Observable.merge_concurrent(2, a, b, c) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_accepts_scheduler_as_second_argument
    a        = cold('  -1-|')
    expected = msgs('---1-|')
    actual = scheduler.configure do
      Rx::Observable.merge_concurrent(2, Rx::ImmediateScheduler.instance, a)
    end
    assert_msgs expected, actual
  end

  def test_fail_on_bad_concurrency
    assert_raises(ArgumentError) do
      Rx::Observable.empty.merge_concurrent(nil)
    end
  end
end
