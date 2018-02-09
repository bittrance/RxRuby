require 'test_helper'

class TestOperatorTakeWhile < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_values_until_block_falsy
    source      = cold('  -123456|')
    expected    = msgs('---123|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.take_while { |x| x < 4 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end

class TestOperatorTakeWhileWithIndex < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_values_until_block_falsy
    source      = cold('  -54321|')
    expected    = msgs('---543|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.take_while_with_index { |x, i| x > i }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_value
    source      = cold('  -a|', a: nil)
    expected    = msgs('---a|', a: nil)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.take_while_with_index { |x, _| true }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.take_while_with_index { |_, _| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.take_while_with_index { |x, i| [i, x] }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end