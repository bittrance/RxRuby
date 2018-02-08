require 'test_helper'

class TestOperatorToA < Minitest::Test
  include Rx::MarbleTesting

  def test_collects_sequence_into_array_on_complete
    source      = cold('  -123|')
    expected    = msgs('------(a|)', a: [1, 2, 3])
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.to_a }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_value
    source      = cold('  -a|', a: nil)
    expected    = msgs('----(a|)', a: [nil])
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.to_a }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.to_a }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
