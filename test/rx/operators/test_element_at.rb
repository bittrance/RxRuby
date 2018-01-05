require 'test_helper'

class TestOperatorElementAt < Minitest::Test
  include Rx::MarbleTesting
  
  def test_returns_nth_element
    left       = cold('  -123|')
    expected   = msgs('----(2|)')
    left_subs  = subs('  ^ !')

    actual = scheduler.configure { left.element_at(1) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
  
  def test_propagates_error
    left       = cold('  -#')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.element_at(0) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_fails_on_empty
    my_err = ->(err) { err.is_a?(RuntimeError) && err.message.include?('too few elements') }

    left       = cold('  -1|')
    expected   = msgs('----#', error: my_err)
    left_subs  = subs('  ^ !')

    actual = scheduler.configure { left.element_at(1) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_raises_on_negative_index
    left = cold('  -1|')
    assert_raises(ArgumentError) do
      left.element_at(-1)
    end
  end

  def test_raises_on_non_numerical_index
    left = cold('  -1|')
    assert_raises(ArgumentError) do
      left.element_at('foo')
    end
  end
end

class TestOperatorElementAtOrDefault < Minitest::Test
  include Rx::MarbleTesting
  
  def test_default_value_on_empty
    left       = cold('  -|')
    expected   = msgs('---(2|)')
    left_subs  = subs('  ^!')

    actual = scheduler.configure { left.element_at_or_default(1, 2) }

    assert_msgs expected, actual
    assert_subs left_subs, left
  end
end