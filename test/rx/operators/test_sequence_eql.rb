require 'test_helper'

class TestOperatorSequenceEql < Minitest::Test
  include Rx::MarbleTesting

  def test_true_when_left_disjunct_identical_sequences
    left       = cold('  123|')
    right      = cold('  ----123|')
    expected   = msgs('---------(t|)', t: true)
    left_subs  = subs('  ^  !')
    right_subs = subs('  ^      !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_when_left_disjunct_sequence_differs
    left       = cold('  12|')
    right      = cold('  ----123|')
    expected   = msgs('--------(f|)', f: false)
    left_subs  = subs('  ^ !')
    right_subs = subs('  ^     !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_on_first_left_difference_in_disjunct_seq
    left       = cold('  -124|')
    right      = cold('  -----123|')
    expected   = msgs('---------(f|)', f: false)
    left_subs  = subs('  ^   !')
    right_subs = subs('  ^      !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_on_overlapping_with_right_queue_on_left_complete
    left       = cold('  -12-|')
    right      = cold('  -123-|')
    expected   = msgs('------(f|)', f: false)
    left_subs  = subs('  ^   !')
    right_subs = subs('  ^   !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_true_when_left_two_empty_sequences
    left       = cold('  -|')
    right      = cold('  --|')
    expected   = msgs('----(t|)', t: true)
    left_subs  = subs('  ^!')
    right_subs = subs('  ^ !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_true_when_parallel_identical_sequences_left
    left       = cold('  -123|')
    right      = cold('  -123---|')
    expected   = msgs('---------(t|)', t: true)
    left_subs  = subs('  ^   !')
    right_subs = subs('  ^      !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_true_when_right_disjunct_identical_sequences
    left       = cold('  ----123|')
    right      = cold('  123|')
    expected   = msgs('---------(t|)', t: true)
    left_subs  = subs('  ^      !')
    right_subs = subs('  ^  !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_when_right_disjunct_sequence_differs
    left       = cold('  ----123|')
    right      = cold('  12|')
    expected   = msgs('--------(f|)', f: false)
    left_subs  = subs('  ^     !')
    right_subs = subs('  ^ !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_on_first_right_difference_in_disjunct_seq
    left       = cold('  -----123|')
    right      = cold('  -124|')
    expected   = msgs('---------(f|)', f: false)
    left_subs  = subs('  ^      !')
    right_subs = subs('  ^   !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_false_on_overlapping_with_left_queue_on_right_complete
    left       = cold('  -123-|')
    right      = cold('  -12-|')
    expected   = msgs('------(f|)', f: false)
    left_subs  = subs('  ^   !')
    right_subs = subs('  ^   !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_true_when_right_two_empty_sequences
    left       = cold('  --|')
    right      = cold('  -|')
    expected   = msgs('----(t|)', t: true)
    left_subs  = subs('  ^ !')
    right_subs = subs('  ^!')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_true_when_parallel_identical_sequences_right
    left       = cold('  -123---|')
    right      = cold('  -123|')
    expected   = msgs('---------(t|)', t: true)
    left_subs  = subs('  ^      !')
    right_subs = subs('  ^   !')

    actual = scheduler.configure do
      left.sequence_eql?(right)
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end
end
