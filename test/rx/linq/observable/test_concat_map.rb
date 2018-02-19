require 'test_helper'

class TestOperatorConcatMap < Minitest::Test
  include Rx::MarbleTesting

  def test_concat_two_sequences_with_selector
    a           = cold('  12-|')
    b           = cold('     3-4|')
    source      = cold('  ab|', a: a, b: b)
    expected    = msgs('--12-4-5|')
    a_subs      = subs('--^--!')
    b_subs      = subs('-----^--!')
    source_subs = subs('--^-!')

    actual = scheduler.configure do
      source.concat_map(
        lambda { |x, i| x.map { |v| v + i } }
      )
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs source_subs, source
  end

  def test_concat_two_sequences_with_single_value
    source      = cold('  1-1|')
    expected    = msgs('--3-43-4|')
    source_subs = subs('--^--!')

    actual = scheduler.configure do
      source.concat_map(cold('3-4|'))
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_concat_two_sequences_with_array
    source      = cold('  1-1|')
    expected    = msgs('--(34)-(34)|')
    source_subs = subs('--^--!')

    actual = scheduler.configure do
      source.concat_map([3, 4])
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_concat_two_sequences_with_result_selector
    a           = cold('  12-|')
    b           = cold('     3-4|')
    source      = cold('  ab|', a: a, b: b)
    expected    = msgs('--pq-r-s|', p: [1, 0, 0], q: [2, 0, 1], r: [3, 1, 0], s: [4, 1, 1])
    a_subs      = subs('--^--!')
    b_subs      = subs('-----^--!')
    source_subs = subs('--^-!')

    actual = scheduler.configure do
      source.concat_map(
        lambda { |x, i| x },
        lambda { |_, *args| args }
      )
    end

    assert_msgs expected, actual
    assert_subs a_subs, a
    assert_subs b_subs, b
    assert_subs source_subs, source
  end

  def test_concat_sequences_with_inner_array
    source      = cold('  a-b|', a: [1, 2], b: [3, 4])
    expected    = msgs('--(12)-(34)|')
    source_subs = subs('--^--!')

    actual = scheduler.configure do
      source.concat_map(
        lambda { |x, i| x },
        lambda { |_, y, _, _| y }
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_selector_raises
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map(lambda { |*_| raise error })
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_selector_error
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map(lambda { |*_| cold('#') })
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_result_selector_raises
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map(
        lambda { |*_| cold('1') },
        lambda { |*_| raise error }
      )
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('--^!')

    actual = scheduler.configure do
      source.concat_map(lambda { |x, i| x })
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end