require 'test_helper'

class TestOperatorStartWith < Minitest::Test
  include Rx::MarbleTesting
  
  def test_start_with_prepends_values
    source      = cold('  -2|')
    expected    = msgs('--(1-)2|')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.start_with(1) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_start_with_aborts_on_error_right
    source      = cold('  -2#')
    expected    = msgs('--(1-)2#')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.start_with(1) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end