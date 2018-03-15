require 'test_helper'

class TestOperatorForkJoin < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_results_from_all
    a           = cold('  --a|')
    b           = cold('  b|')
    c           = cold('  -c--|')
    expected    = msgs('------(r|)', r: %w[a b c])
    a_subs      = subs('  ^   !') # Should unsub @500
    b_subs      = subs('  ^   !') # Should unsub @300
    c_subs      = subs('  ^   !')

    actual = scheduler.configure { Rx::Observable.fork_join(a, b, c) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_emit_last_result
    a           = cold('  123|')
    b           = cold('  --4|')
    expected    = msgs('-----(r|)', r: [3, 4])
    a_subs      = subs('  ^  !')
    b_subs      = subs('  ^  !')

    actual = scheduler.configure { Rx::Observable.fork_join(a, b) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_propagates_error
    a           = cold('  -#')
    b           = cold('  b--|')
    expected    = msgs('---#')
    a_subs      = subs('  ^!')
    b_subs      = subs('  ^!')

    actual = scheduler.configure { Rx::Observable.fork_join(a, b) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_empty_argument_completes_immediately
    actual = scheduler.configure { Rx::Observable.fork_join }
    assert_msgs msgs('--|'), actual
  end
end