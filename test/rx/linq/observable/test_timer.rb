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

  def test_emit_value_at_point_in_time
    actual = scheduler.configure do
      Rx::Observable.timer(Rx::TestTime.new(300), scheduler)
    end

    assert_msgs msgs('---(0|)'), actual
  end

  def test_emit_periodic_values_after_point_in_time
    actual = scheduler.configure do
      Rx::Observable.timer(Rx::TestTime.new(500), 300, scheduler)
    end

    assert_msgs msgs('-----0--1--'), actual
  end
end
