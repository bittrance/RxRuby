require 'test_helper'

class TestOperatorZip < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_pairs_in_arrival_order
    a        = cold('  -12-3-|')
    b        = cold('  ---4-5|')
    expected = msgs('-----a-b|', a: [1, 4], b: [2, 5])
    a_subs   = subs('--^-----!')
    b_subs   = subs('--^-----!')

    actual = scheduler.configure { a.zip(b) }

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end
end

class TestObservableZip < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_when_all_source_omitted_once
    a        = cold('  -1----4|')
    b        = cold('  --2--5-|')
    c        = cold('  ---36--|')
    expected = msgs('-----a--b|', a: [1, 2, 3], b: [4, 5, 6])
    a_subs   = subs('--^------!')
    b_subs   = subs('--^------!')
    c_subs   = subs('--^------!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b, c)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs c_subs, c
  end

  def test_emit_pairs_in_arrival_order
    a        = cold('  -12-3-|')
    b        = cold('  ---4-5|')
    expected = msgs('-----a-b|', a: [1, 4], b: [2, 5])
    a_subs   = subs('--^-----!')
    b_subs   = subs('--^-----!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_complete_when_first_completes_no_buffers
    a        = cold('  -1-|')
    b        = cold('  --2-|')
    expected = msgs('----a|', a: [1, 2])
    a_subs   = subs('--^--!')
    b_subs   = subs('--^--!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_complete_when_first_complete_and_queue_empty
    a        = cold('  -12|')
    b        = cold('  ---34--|')
    expected = msgs('-----a(b|)', a: [1, 3], b: [2, 4])
    a_subs   = subs('--^--!')
    b_subs   = subs('--^---!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_propagate_error_from_when_no_buffer
    a        = cold('  -1---|')
    b        = cold('  --2#')
    expected = msgs('----a#', a: [1, 2])
    a_subs   = subs('--^--!')
    b_subs   = subs('--^--!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_propagate_error_from_when_when_buffered
    a        = cold('  -1-2--|')
    b        = cold('  --3-#')
    expected = msgs('----a-#', a: [1, 3])
    a_subs   = subs('--^---!')
    b_subs   = subs('--^---!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b)
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_apply_selector_before_emission
    a        = cold('  -1-|')
    b        = cold('  --2-|')
    expected = msgs('----3|')
    a_subs   = subs('--^--!')
    b_subs   = subs('--^--!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b) { |*values| values.inject(0, :+) }
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end

  def test_propagate_error_raised_in_selector
    a        = cold('  -123--|')
    b        = cold('  ----4-|')
    expected = msgs('------#')
    a_subs   = subs('--^---!')
    b_subs   = subs('--^---!')

    actual = scheduler.configure do
      Rx::Observable.zip(a, b) { |_| raise error }
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
  end
end
