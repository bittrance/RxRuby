require 'test_helper'

class TestOperatorDistinct < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_only_unique_items
    source      = cold('  -112231|')
    expected    = msgs('---1-2-3-|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.distinct }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_respects_nil_as_value
    source      = cold('  -aab|', a: nil)
    expected    = msgs('---a-b|', a: nil)
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.distinct }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_block_selects_value_for_uniqueness_test
    source      = cold('  -1325|')
    expected    = msgs('---1-2-|')
    source_subs = subs('  ^    !')

    actual = scheduler.configure do
      source.distinct { |x| x % 2 == 0 }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_erroring_block
    source      = cold('  -1|')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do
      source.distinct { raise error }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.distinct }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.distinct }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end