require 'test_helper'

class TestOperatorIgnoreElements < Minitest::Test
  include Rx::MarbleTesting

  def test_ony_outputs_on_completed
    source      = cold('  -123|')
    expected    = msgs('------|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.ignore_elements }

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
