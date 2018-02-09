require 'test_helper'

class TestOperatorSkipWhile < Minitest::Test
  include Rx::MarbleTesting

  def test_ignore_values_until_block_falsy
    source      = cold('  -123456|')
    expected    = msgs('------456|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure do
      source.skip_while { |x| x < 4 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end

class TestOperatorSkipWhileWithIndex < Minitest::Test
  include Rx::MarbleTesting

  def test_ignore_values_until_block_falsy
    source      = cold('  -54321|')
    expected    = msgs('------21|')
    source_subs = subs('  ^     !')

    actual = scheduler.configure do
      source.skip_while_with_index { |x, i| x > i }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_stops_calling_block_after_false
    call_count = 0
    source = cold('  -54321|')

    scheduler.configure do
      source.skip_while_with_index do |x, i|
        call_count += 1
        x > i
      end
    end
    assert_equal 4, call_count
  end

  def test_respects_nil_as_value
    source      = cold('  -a|', a: nil)
    expected    = msgs('---a|', a: nil)
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.skip_while_with_index { |x, _| false }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_erroring_block
    source      = cold('  -1')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.skip_while_with_index { |_, _| raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.skip_while_with_index { |x, i| [i, x] }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
