require 'test_helper'

class TestScheduledObserver < Minitest::Test
  include Rx::MarbleTesting

  def setup
    @observer = scheduler.create_observer
    @another_scheduler = Rx::TestScheduler.new
    @protagonist = Rx::ScheduledObserver.new(@another_scheduler, @observer)
  end

  def test_uses_separate_scheduler_for_on_next
    source = cold('-123|')
    source.subscribe(@protagonist)
    scheduler.advance_to(200)
    assert_msgs [], @observer
    @another_scheduler.advance_to(200)
    assert_msgs msgs('--(12)'), @observer
    scheduler.advance_to(400)
    assert_msgs msgs('--(12)'), @observer
    @another_scheduler.advance_to(400)
    assert_msgs msgs('--(12)-(3|)'), @observer
  end

  def test_uses_separate_scheduler_for_on_error
    source = cold('-#')
    source.subscribe(@protagonist)
    scheduler.advance_to(200)
    assert_msgs [], @observer
    @another_scheduler.advance_to(200)
    assert_msgs msgs('--#'), @observer
  end

  def test_stops_on_erroring_observer
    flaky_observer = Rx::Observer.configure do |o|
      o.on_next do |x|
        if x == 'X'
          raise error
        else
          @observer.on_next(x)
        end
      end
      o.on_error(&@observer.method(:on_error))
      o.on_completed(&@observer.method(:on_completed))
    end
    protagonist = Rx::ScheduledObserver.new(scheduler, flaky_observer)
    source = cold('-1X1')
    source.subscribe(protagonist)
    scheduler.advance_to(400)
    assert_msgs msgs('-1#'), @observer
  end

  def test_unsubscribe_stops_scheduled_actions
    source = cold('-123|')
    source.subscribe(@protagonist)
    scheduler.advance_to(200)
    @another_scheduler.advance_to(200)
    scheduler.advance_to(400)
    assert_msgs msgs('--(12)'), @observer
    @protagonist.unsubscribe
    @another_scheduler.advance_to(400)
    assert_msgs msgs('--(12)'), @observer
  end
end
