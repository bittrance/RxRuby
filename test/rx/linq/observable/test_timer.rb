require 'test_helper'

class TestOperatorTimer < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_single_value_after_delay
    actual = scheduler.configure do
      Rx::Observable.timer(100, scheduler)
    end

    assert_msgs msgs('---(0|)'), actual
  end

  def test_emit_periodic_values
    actual = scheduler.configure do
      Rx::Observable.timer(0, 300, scheduler)
    end

    assert_msgs msgs('--0--1--2--'), actual
  end

  def test_emit_periodic_values_after_delay
    actual = scheduler.configure do
      Rx::Observable.timer(300, 300, scheduler)
    end

    assert_msgs msgs('-----0--1--'), actual
  end
end

class TestOperatorAsyncTimer < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
  end

  def test_emit_value_at_point_in_time
    Rx::Observable.timer(Time.now).subscribe(@observer)
    await_array_length(@observer.messages, 2)
    expected = [on_next(0, 0), on_completed(0)]
    assert_equal expected, @observer.messages
  end

  def test_emit_value_at_repeated_point_in_time
    Rx::Observable.timer(Time.now, 0.01).subscribe(@observer)
    await_array_length(@observer.messages, 3)
    events = @observer.messages.map {|m|  m.value }
    assert events.all? {|v| Rx::OnNextNotification === v }
    assert_equal [0, 1, 2], events.map {|v| v.value }.slice(0, 3)
  end
end
