require 'test_helper'

class TestOperatorDistinctUntilChanged < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_value_if_different_from_previous
    source      = cold('  1122231|')
    expected    = msgs('--1-2--31|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.distinct_until_changed }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_value
    source      = cold('  -aab|', a: nil)
    expected    = msgs('---a-b|', a: nil)
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.distinct_until_changed }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_compares
    source      = cold('  -123|')
    expected    = msgs('---1-3|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure do
      source.distinct_until_changed do |l, r|
        l + 1 == r
      end
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_does_not_see_first_value
    source = cold('  -123|')
    n = 0

    scheduler.configure do
      source.distinct_until_changed { n += 1 }
    end
    
    assert_equal 2, n
  end

  def test_erroring_block
    source      = cold('  -12|')
    expected    = msgs('---1#')
    source_subs = subs('  ^ !')

    actual = scheduler.configure do
      source.distinct_until_changed { raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.distinct_until_changed }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.distinct_until_changed }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
