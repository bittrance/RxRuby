require 'test_helper'

class TestOperatorTake < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_only_first_three_values_and_complete
    source      = cold('  -123456|')
    expected    = msgs('---12(3|)')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.take(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_complete_before_take_count
    source      = cold('  -12|')
    expected    = msgs('---12|')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.take(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emit_nothing_on_count_zero
    source      = cold('  -123|')
    expected    = msgs('--|')
    source_subs = subs('   ')

    actual = scheduler.configure { source.take(0) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.take(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_require_positive_count
    source = cold('  -|')
    assert_raises(ArgumentError) do
      source.take(-1)
    end
  end
end
