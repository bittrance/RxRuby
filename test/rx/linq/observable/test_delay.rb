require 'test_helper'

class TestOperatorDelay < Minitest::Test
  include Rx::MarbleTesting

  def test_delay_disjunct_items_by_due_time
    source      = cold('  -1--2|')
    expected    = msgs('-----1--(2|)')
    source_subs = subs('  ^    !')

    actual = scheduler.configure { source.delay(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_delay_overlapping_items_by_due_time
    source      = cold('  -12|')
    expected    = msgs('-----1(2|)')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.delay(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_emits_simultaneous_items_simultaneously
    source      = cold('  -(12)--|')
    expected    = msgs('-----(12)|')
    source_subs = subs('  ^   !')

    actual = scheduler.configure { source.delay(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagate_error
    source      = cold('  -1#')
    expected    = msgs('----#')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.delay(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_propagate_completion
    source      = cold('  --|')
    expected    = msgs('----|')
    source_subs = subs('  ^ !')

    actual = scheduler.configure { source.delay(200, scheduler) }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_raises_on_negative_due_time
    source = cold('  -1')
    assert_raises(ArgumentError) do
      source.delay(-1)
    end
  end
end

class TestOperatorAsyncDelay < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
  end

  def test_passing_time_now
    Rx::Observable.just(42)
      .delay(Time.now).subscribe(@observer)
    await_array_length(@observer.messages, 2)
    expected = [on_next(0, 42), on_completed(0)]
    assert_equal expected, @observer.messages
  end

  def test_passing_datetime_now
    Rx::Observable.just(42)
      .delay(DateTime.now).subscribe(@observer)
    await_array_length(@observer.messages, 2)
    expected = [on_next(0, 42), on_completed(0)]
    assert_equal expected, @observer.messages
  end
end