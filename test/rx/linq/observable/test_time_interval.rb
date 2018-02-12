require 'test_helper'

class TestOperatorTimeInterval < Minitest::Test
  include Rx::MarbleTesting

  def test_wrap_value_with_delta_from_previous
    source      = cold('  1--2-3|')
    expected    = msgs('--a--b-c|', 
      a: Rx::TimeInterval.new(0, 1), 
      b: Rx::TimeInterval.new(300, 2),
      c: Rx::TimeInterval.new(200, 3))
    source_subs = subs('  ^     !')

    actual = scheduler.configure do
      source.time_interval(scheduler)
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.time_interval }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end