require 'test_helper'

class TestOperatorTimestamp < Minitest::Test
  include Rx::MarbleTesting

  def test_wrap_each_value_with_timestamp
    source      = cold('  -1--2|')
    expected    = msgs('---a--b|',
      a: Rx::Timestamp.new(300, 1), 
      b: Rx::Timestamp.new(600, 2))
    source_subs = subs('  ^    !')

    actual = scheduler.configure { source.timestamp(scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.timestamp(scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
