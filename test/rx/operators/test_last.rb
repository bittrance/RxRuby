require 'test_helper'

class TestOperatorLast < Minitest::Test
  include Rx::MarbleTesting
  
  def test_returns_last
    left       = cold('  -123|')
    expected   = msgs('------(3|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure { left.last }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
  
  def test_propagates_error
    left       = cold('  -#')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.last }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_block_selects_last
    left       = cold('  -123|')
    expected   = msgs('------(2|)')
    left_subs  = subs('  ^   !')

    actual = scheduler.configure do
      left.last { |n| n < 3 }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_erroring_block
    left       = cold('  -123|')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure do
      left.last { |n| raise error }
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_empty
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('no elements') }

    left       = cold('  -|')
    expected   = msgs('---#', error: my_err)
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.last }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end

class TestOperatorLastOrDefault < Minitest::Test
  include Rx::MarbleTesting
  
  def test_default_value_on_empty
    left       = cold('  -|')
    expected   = msgs('---(2|)')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.last_or_default(2) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end