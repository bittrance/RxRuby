require 'test_helper'

class TestCreationRepeat < Minitest::Test
  include Rx::MarbleTesting

  def test_repeat_letter
    actual = scheduler.configure { Rx::Observable.repeat('a', 3, scheduler) }
    assert_msgs msgs('--(aaa|)'), actual
  end
end

class TestOperatorRepeat < Minitest::Test
  include Rx::AsyncTesting
  include Rx::MarbleTesting

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
  end

  def test_repeat
    source      = cold('  -12|')
    expected    = msgs('---12-12|')
    source_subs = subs('  ^  (!^)  !')

    actual = scheduler.configure { source.repeat(2) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_repeat_stops_with_on_error
    source      = cold('  -12#')
    expected    = msgs('---12#')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.repeat(2) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_repeat_throws_argument_error_on_bad_count
    assert_raises(ArgumentError) do
      scheduler.create_cold_observable(
        on_completed(100)
      ).repeat(nil)
    end
  end
  
  def test_repeat_infinitely
    subscription = Rx::Observable.of(1, 2)
      .repeat_infinitely
      .subscribe_on(Rx::DefaultScheduler.instance)
      .subscribe(@observer)
    await_array_minimum_length(@observer.messages, 10)
    subscription.unsubscribe
    expected = ([
      on_next(0, 1),
      on_next(0, 2)
    ] * 5).flatten
    assert_messages expected, @observer.messages.take(10)
  end
  
  def test_repeat_infinitely_breaks_on_error
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_error(100, @err)
      ).repeat_infinitely
    end
    expected = [
      on_error(SUBSCRIBED + 100, @err)
    ]
    assert_messages expected, res.messages
  end
end