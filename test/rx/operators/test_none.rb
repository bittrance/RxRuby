require 'test_helper'

class TestOperatorNone < Minitest::Test
  include Rx::MarbleTesting
  
  def test_emit_false_for_any_truthy_values
    source       = cold('  -a|')
    expected     = msgs('---(f|)', f: false)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.none? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_true_for_all_falsy_sequence
    source       = cold('  -fnfn|', f: false, n: nil)
    expected     = msgs('-------(t|)', t: true)
    source_subs  = subs('  ^    !')

    actual = scheduler.configure { source.none? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_true_on_empty_sequence
    source       = cold('  -|')
    expected     = msgs('---(t|)', t: true)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.none? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -#')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.none? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_true_when_no_elements_match_block
    source       = cold('  -123|')
    expected     = msgs('------(t|)', t: true)
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.none? { |n| n < 1 } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_false_when_one_element_matches_block
    source       = cold('  -123|')
    expected     = msgs('----(f|)', f: false)
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.none? { |n| n == 2 } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -123|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.none? { |n| raise error } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end