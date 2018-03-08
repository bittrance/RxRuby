require 'test_helper'

class TestCreationRepeat < Minitest::Test
  include Rx::MarbleTesting

  def test_repeat_letter
    actual = scheduler.configure { Rx::Observable.repeat('a', 3, scheduler) }
    assert_msgs msgs('--(aaa|)'), actual
  end
end

class TestCreationRepeat < Minitest::Test
  include Rx::ReactiveTest

  def test_repeat_infinitely_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 203) do
      Rx::Observable.repeat_infinitely({a: 1}, scheduler)
    end

    msgs = [
        on_next(201, {a: 1}),
        on_next(202, {a: 1})
    ]
    assert_messages msgs, res.messages
  end
end

class TestOperatorRepeat < Minitest::Test
  include Rx::MarbleTesting

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
    source      = cold('12|')
    expected    = msgs('--12121212')
    source_subs = subs('  ^ (!^) (!^) (!^) !')
    actual = scheduler.configure { source.repeat_infinitely }
    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_repeat_infinitely_breaks_on_error
    source      = cold('  -12#')
    expected    = msgs('---12#')
    source_subs = subs('  ^  !')

    actual = scheduler.configure { source.repeat_infinitely }

    assert_msgs expected, actual
    assert_subs source_subs, source
  end
end
