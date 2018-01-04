require 'test_helper'

class TestOperatorSum < Minitest::Test
  include Rx::MarbleTesting
  
  def test_calculates_sum_of_emitted_values
    source       = cold('  -123|')
    expected     = msgs('------(6|)')
    source_subs  = subs('  ^   !')

    actual = scheduler.configure { source.sum }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_maps_with_block
    source       = cold('  -123|')
    expected     = msgs('------(9|)')
    source_subs  = subs('  ^   !')

    actual = scheduler.configure do
      source.sum { |n| n + 1 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source       = cold('  -2424|')
    expected     = msgs('---#')
    source_subs  = subs('  ^!')

    actual = scheduler.configure do
      source.sum { |n| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source       = cold('  -2#')
    expected     = msgs('----#')
    source_subs  = subs('  ^ !')

    actual = scheduler.configure { source.sum }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_fails_on_non_numerical_input
    my_err = ->(err) { err.is_a?(TypeError) && err.message.match(/blah.*numerical/) }

    source       = cold('  -a', a: 'blah')
    expected     = msgs('---#', error: my_err)
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.sum }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_zero_on_empty
    source       = cold('  -|')
    expected     = msgs('---(0|)')
    source_subs  = subs('  ^!')

    actual = scheduler.configure { source.sum }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end