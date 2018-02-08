require 'test_helper'

class TestOperatorDematerialize < Minitest::Test
  include Rx::MarbleTesting

  def test_dematerialize_on_next
    source      = cold('  -a|', a: Rx::Notification.create_on_next('a'))
    expected    = msgs('---a|')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.dematerialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_dematerialize_on_error
    source      = cold('  -a|', a: Rx::Notification.create_on_error(error))
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.dematerialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
  
  def test_dematerialize_on_completed
    source      = cold('  -a|', a: Rx::Notification.create_on_completed)
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.dematerialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.dematerialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagates_completion
    source      = cold('  -|')
    expected    = msgs('---|')
    source_subs = subs('  ^!')

    actual = scheduler.configure { source.dematerialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end