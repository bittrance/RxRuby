require 'test_helper'

class TestOperatorTakeUntil < Minitest::Test
  include Rx::MarbleTesting

  def test_propagates_left_event
    left       = cold('  a-b-c|')
    right      = cold('  ------')
    expected   = msgs('--a-b-c|')
    left_subs  = subs('  ^    !')
    right_subs = subs('  ^    !')

    actual = scheduler.configure { left.take_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_propagates_left_error
    left       = cold('  a-b#')
    right      = cold('  ----')
    expected   = msgs('--a-b#')
    left_subs  = subs('  ^  !')
    right_subs = subs('  ^  !')

    actual = scheduler.configure { left.take_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_completes_on_right_event
    left       = cold('  a-b-c|')
    right      = cold('  ---1-|')
    expected   = msgs('--a-b|')
    left_subs  = subs('--^--!')
    right_subs = subs('--^--!')

    actual = scheduler.configure { left.take_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_propagate_right_error
    left       = cold('  a-b-c|')
    right      = cold('  ---#-|')
    expected   = msgs('--a-b#')
    left_subs  = subs('--^--!')
    right_subs = subs('--^--!')

    actual = scheduler.configure { left.take_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_ignore_completing_right
    left       = cold('  a-b-c|')
    right      = cold('  ---|')
    expected   = msgs('--a-b-c|')
    left_subs  = subs('--^----!')
    right_subs = subs('--^--!')

    actual = scheduler.configure { left.take_until(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end