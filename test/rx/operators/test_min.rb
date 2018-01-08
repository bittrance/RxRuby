require 'test_helper'

class TestOperatorMin < Minitest::Test
  include Rx::MarbleTesting

  def test_min_value_from_numerical_sequence
    left       = cold('  -132|')
    expected   = msgs('------(1|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure { left.min }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_nil_on_empty_sequence
    left       = cold('  -|')
    expected   = msgs('---(a|)', a: nil)
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.min }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_propagates_error
    left       = cold('  -#')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.min }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_min_value_as_dictated_by_block
    left       = cold('  -123|')
    expected   = msgs('------(3|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure do
      left.min { |l, r| r <=> l }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_block_equivocates_on_all_values
    left       = cold('  -123|')
    expected   = msgs('------(1|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure { left.min { |l, r| 0 } }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_erroring_block
    left       = cold('  -123|')
    expected   = msgs('----#')
    left_subs  = subs('  ^ !')

    actual = scheduler.configure do
      left.min { |l, r| raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end
