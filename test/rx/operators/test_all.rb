require 'test_helper'

class TestOperatorAll < Minitest::Test
  include Rx::MarbleTesting
  
  def test_emit_false_on_first_falsy_value
    source       = cold('  -f11|', f: false)
    expected     = msgs('---(f|)', f: false)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.all? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_true_for_sequence_of_truthy_values
    source       = cold('  -t1|', t: true)
    expected     = msgs('-----(t|)', t: true)
    source_subs  = subs('  ^  !')

    actual = scheduler.configure { source.all? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_true_on_empty_sequence
    source       = cold('  -|')
    expected     = msgs('---(t|)', t: true)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.all? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -#')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.all? }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_true_when_all_elements_match_block
    source       = cold('  -123|')
    expected     = msgs('------(t|)', t: true)
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.all? { |n| n > 0 } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_false_when_one_element_fails_block
    source       = cold('  -123|')
    expected     = msgs('----(f|)', f: false)
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.all? { |n| n != 2 } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -123|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.all? { |n| raise error } }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end