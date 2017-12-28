require 'test_helper'

class TestOperatorMerge < Minitest::Test
  include Rx::MarbleTesting

  def test_merge_two_sequences_in_order_of_arrival
    left       = cold('  ---c|')
    right      = cold('  -ab--d|')
    expected   = msgs('---abc-d|')
    left_subs  = subs('--^---!')
    right_subs = subs('--^-----!')
    res = scheduler.configure { left.merge(right) }
    assert_msgs expected, res
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_merge_no_complete_unless_all_complete
    left       = cold('  ---c|')
    right      = cold('  -ab')
    expected   = msgs('---abc-')
    right_subs = subs('--^-------!')
    res = scheduler.configure { left.merge(right) }
    assert_msgs expected, res
    assert_subs right_subs, right
  end

  def test_unsusbscribe_all_on_erroring_left
    left       = cold('  --#')
    right      = cold('  -a-b')
    expected   = msgs('---a#')
    left_subs  = subs('--^-!')
    right_subs = subs('--^-!')
    res = scheduler.configure { left.merge(right) }

    assert_msgs expected, res
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end
