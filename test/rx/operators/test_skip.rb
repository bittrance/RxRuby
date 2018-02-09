require 'test_helper'

class TestOperatorSkip < Minitest::Test
  include Rx::MarbleTesting

  def test_skip_first_three_values
    source      = cold('  -123456|')
    expected    = msgs('------456|')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.skip(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_nothing_on_complete_before_skip_count
    source      = cold('  -12|')
    expected    = msgs('-----|')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.skip(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_skip_nothing_on_zero
    source      = cold('  -123|')
    expected    = msgs('---123|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.skip(0) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.skip(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_require_positive_count
    source = cold('  -|')
    assert_raises(ArgumentError) do
      source.skip(-1)
    end
  end
end
