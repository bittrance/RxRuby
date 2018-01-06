require 'test_helper'

class TestOperatorSingle < Minitest::Test
  include Rx::MarbleTesting
  
  def test_returns_single_value_on_completion
    left       = cold('  -1-|')
    expected   = msgs('-----(1|)')
    left_subs  = subs('  ^  !')

    actual = scheduler.configure { left.single }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_sequence_with_multiple_values
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('More than one') }

    left       = cold('  -12|')
    expected   = msgs('----#', error: my_err)
    left_subs  = subs('  ^ !')

    actual = scheduler.configure { left.single }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_propagates_error
    left       = cold('  -#')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.single }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_block_selects_single_value
    left       = cold('  -123|')
    expected   = msgs('------(2|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure do
      left.single { |n| n == 2 }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_block_selecting_multiple_values
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('More than one') }

    left       = cold('  -22|')
    expected   = msgs('----#', error: my_err)
    left_subs  = subs('  ^ !')

    actual = scheduler.configure do
      left.single { |n| n == 2 }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_erroring_block
    left       = cold('  -123|')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure do
      left.single { |n| raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_empty_sequence
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('no elements') }

    left       = cold('  -|')
    expected   = msgs('---#', error: my_err)
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.single }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end

class TestOperatorSingleOrDefault < Minitest::Test
  include Rx::MarbleTesting

  def test_emits_default_value_on_empty_sequence
    left       = cold('  -|')
    expected   = msgs('---(2|)')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.single_or_default(2) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_multiple_even_with_default
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('More than one') }

    left       = cold('  -12|')
    expected   = msgs('----#', error: my_err)
    left_subs  = subs('  ^ !')

    actual = scheduler.configure { left.single_or_default(3) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end