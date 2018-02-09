require 'test_helper'

class TestOperatorDefaultIfEmpty < Minitest::Test
  include Rx::MarbleTesting

  def test_default_if_empty
    source      = cold('  -|')
    expected    = msgs('---(9|)')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.default_if_empty(9) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_no_default_on_emission
    source      = cold('  -1|')
    expected    = msgs('---1|')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.default_if_empty(9) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.default_if_empty(9) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end