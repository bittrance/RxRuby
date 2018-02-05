require 'test_helper'

class TestOperatorTakeLast < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_last_values_on_completion
    source      = cold('  -123456|')
    expected    = msgs('---------(456|)')
    source_subs = subs('  ^      !')

    actual = scheduler.configure { source.take_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emits_all_elements_when_fewer_than_count
    source      = cold('  -12|')
    expected    = msgs('-----(12|)')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.take_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.take_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.take_last(3) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_argument_error_on_negative_count
    source = cold('  -|')
    assert_raises(ArgumentError) do
      source.take_last(-1)
    end
  end
end
