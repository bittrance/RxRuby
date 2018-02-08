require 'test_helper'

class TestOperatorAny < Minitest::Test
  include Rx::MarbleTesting
  
  def test_emit_true_on_first_truthy_element
    source       = cold('  -123|')
    expected     = msgs('---(t|)', t: true)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.any? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_false_on_sequence_of_falsy_values
    source       = cold('  -nnn|', n: nil)
    expected     = msgs('------(f|)', f: false)
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.any? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_false_on_empty_sequence
    source       = cold('  -|')
    expected     = msgs('---(f|)', f: false)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.any? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -#')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.any? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_true_on_first_element_selected_by_block
    source       = cold('  -123|')
    expected     = msgs('----(t|)', t: true)
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.any? { |n| n > 1 } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_false_when_block_returns_false_on_all
    source       = cold('  -123|')
    expected     = msgs('------(f|)', f: false)
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.any? { |n| false } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -123|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.any? { |n| raise error } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end