require 'test_helper'

class TestOperatorMaterialize < Minitest::Test
  include Rx::MarbleTesting

  def test_materialize_on_next_and_on_completed
    source      = cold('  -a|')
    expected    = msgs('---a(b|)', a: Rx::Notification.create_on_next('a'), b: Rx::Notification.create_on_completed)
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.materialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_materialize_on_next_and_on_error
    source      = cold('  -a#')
    expected    = msgs('---a(b|)', a: Rx::Notification.create_on_next('a'), b: Rx::Notification.create_on_error(error))
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.materialize }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end