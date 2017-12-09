require 'test_helper'

class TestOperatorLatest < Minitest::Test
  include Rx::MarbleTesting

  def test_latest_inner_observable_on_next
    a        = cold('  -1-4|')
    b        = cold('    -2-5|')
    c        = cold('      -3|')
    left     = cold('  a-b-c|', a: a, b: b, c: c)
    expected = msgs('---1-2-3|')
    a_subs   = subs('--^-!')
    b_subs   = subs('----^-!')
    c_subs   = subs('------^-!')

    actual = scheduler.configure { left.latest }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_silent_observable_subscribe_unsubscribe
    a        = cold('  -1-|')
    b        = cold('    ---|')
    c        = cold('      -2|')
    left     = cold('  a-b-c|', a: a, b: b, c: c)
    expected = msgs('---1---2|')
    a_subs   = subs('--^-!')
    b_subs   = subs('----^-!')
    c_subs   = subs('------^-!')

    actual = scheduler.configure { left.latest }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_erroring_inner_propagates_error
    a        = cold('  -1#')
    b        = cold('     -2|')
    left     = cold('  a--b|', a: a, b: b)
    expected = msgs('---1#')
    a_subs   = subs('--^-!')
    b_subs   = subs('')

    actual = scheduler.configure { left.latest }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_disjunct_inner_completing_observables
    a        = cold('  -1|')
    b        = cold('      -2|')
    left     = cold('  a---b--|', a: a, b: b)
    expected = msgs('---1---2-|')
    a_subs   = subs('  ^ !')
    b_subs   = subs('      ^ !')

    actual = scheduler.configure { left.latest }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_waiting_for_first_inner_observable
    a        = cold('     -1|')
    left     = cold('  ---a---|', a: a)
    expected = msgs('------1--|')
    a_subs   = subs('     ^ !')

    actual = scheduler.configure { left.latest }

    assert_msgs expected, actual
    assert_subs a_subs, a
  end
end