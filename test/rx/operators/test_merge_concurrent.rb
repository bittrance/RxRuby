require 'test_helper'

class TestOperatorMergeConcurrent < Minitest::Test
  include Rx::MarbleTesting

  def test_merge_three_sequences_two_at_a_time
    a        = cold('  -1-|')
    b        = cold('   -2|')
    c        = cold('     -3|')
    left     = cold('  abc|', a: a, b: b, c: c)
    expected = msgs('---12-3|')
    a_subs   = subs('--^--!')
    b_subs   = subs('---^-!')
    c_subs   = subs('-----^-!')

    res = scheduler.configure { left.merge_concurrent(2) }

    assert_msgs expected, res
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_error_stops_later_subscription
    a        = cold('  -1-|')
    b        = cold('   -#')
    c        = cold('    -3|')
    left     = cold('  abc|', a: a, b: b, c: c)
    expected = msgs('---1#')
    a_subs   = subs('--^-!')
    b_subs   = subs('---^!')
    c_subs   = subs('')

    res = scheduler.configure { left.merge_concurrent(2) }

    assert_msgs expected, res
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_handles_concurrency_exceeding_emissions
    a        = cold('  -1|')
    b        = cold('   --2|')
    left     = cold('  ab|', a: a, b: b)
    expected = msgs('---1-2|')
    a_subs   = subs('--^-!')
    b_subs   = subs('---^--!')

    res = scheduler.configure { left.merge_concurrent(5) }

    assert_msgs expected, res
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_handles_single_emission
    a        = cold('   -1|')
    left     = cold('  -a|', a: a)
    expected = msgs('----1|')
    a_subs   = subs('---^-!')

    res = scheduler.configure { left.merge_concurrent(2) }
    assert_msgs expected, res
    assert_subs a_subs, a
  end

  def test_handles_empty_stream
    empty = cold('-|')
    scheduler.configure { empty.merge_concurrent(2) }
    assert_subs subs('--^!'), empty
  end

  def test_fail_on_bad_concurrency
    assert_raises(ArgumentError) do
      Rx::Observable.empty.merge_concurrent(nil)
    end
  end
end

class TestObservableMergeConcurrent < Minitest::Test
  include Rx::MarbleTesting

  def test_merge_three_sequences_two_at_a_time
    a        = cold('  -1-|')
    b        = cold('  --2|')
    c        = cold('     -3|')
    expected = msgs('---12-3|')
    a_subs   = subs('--^--!')
    b_subs   = subs('--^--!')
    c_subs   = subs('-----^-!')

    actual = scheduler.configure { Rx::Observable.merge_concurrent(2, a, b, c) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_accepts_scheduler_as_second_argument
    a        = cold('  -1-|')
    expected = msgs('---1-|')
    actual = scheduler.configure do
      Rx::Observable.merge_concurrent(2, Rx::ImmediateScheduler.instance, a)
    end
    assert_msgs expected, actual
  end

  def test_fail_on_bad_concurrency
    assert_raises(ArgumentError) do
      Rx::Observable.empty.merge_concurrent(nil)
    end
  end
end
