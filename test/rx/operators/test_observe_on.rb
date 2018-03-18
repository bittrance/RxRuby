require 'test_helper'

class TestOperatorObserveOn < Minitest::Test
  include Rx::MarbleTesting

  def test_notification_on_another_scheduler
    source      = cold('1-2-')
    expected    = msgs('---(1-2)')
    source_subs = subs('^--!')

    another_scheduler = Rx::TestScheduler.new
    actual = scheduler.create_observer
    s1 = source.observe_on(another_scheduler).subscribe(actual)

    another_scheduler.advance_to(300)
    scheduler.advance_to(300)

    assert_msgs [], actual

    another_scheduler.advance_to(400)

    assert_msgs expected, actual
    s1.unsubscribe
    assert_subs source_subs, source
  end

  def test_unsubscribe_stops_notification
    source      = cold('1-2-')

    another_scheduler = Rx::TestScheduler.new
    actual = scheduler.create_observer
    s1 = source.observe_on(another_scheduler).subscribe(actual)

    another_scheduler.advance_to(300)
    scheduler.advance_to(300)
    s1.unsubscribe
    another_scheduler.advance_to(400)

    assert_msgs [], actual
  end
end
