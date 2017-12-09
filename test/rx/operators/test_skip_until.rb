require 'test_helper'

class TestOperatorSkipUntil < Minitest::Test
  include Rx::MarbleTesting

  def test_skip_left_until_right_emits
    left       = cold('  a-b-c-d|')
    right      = cold('  ---1----')
    expected   = msgs('------c-d|')
    left_subs  = subs('  ^      !')
    right_subs = subs('  ^  !')

    actual = scheduler.configure { left.skip_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_propagate_left_error
    left       = cold('  a-#')
    right      = cold('  ---')
    expected   = msgs('----#')
    left_subs  = subs('  ^ !')
    right_subs = subs('  ^ !')

    actual = scheduler.configure { left.skip_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_no_complete_on_infinite_right
    left       = cold('  a-b-c|')
    right      = cold('  ------')
    expected   = msgs('--------')
    left_subs  = subs('  ^    !')
    right_subs = [subscribe(200, 4711)]

    actual = scheduler.configure(disposed: 4711) { left.skip_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_propagates_right_error
    left       = cold('  a-b-c|')
    right      = cold('  -----#')
    expected   = msgs('-------#')
    left_subs  = subs('  ^    !')
    right_subs = subs('  ^    !')

    actual = scheduler.configure { left.skip_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_ignores_completing_right
    left       = cold('  a-b-c|')
    right      = cold('  ---|')
    expected   = msgs('-------|')
    left_subs  = subs('  ^    !')
    right_subs = subs('  ^  !')

    actual = scheduler.configure { left.skip_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end
