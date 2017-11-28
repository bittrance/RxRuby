require 'test_helper'

class TestOperatorConcat < Minitest::Test
  include Rx::MarbleTesting

  def test_concatenates_sequences
    left       = cold('  -12|')
    right      = cold('     -34|')
    expected   = msgs('---12-34|')
    left_subs  = subs('  ^  !')
    right_subs = subs('     ^  !')

    actual = scheduler.configure { left.concat(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_waits_for_each_observable_to_complete
    left       = cold('  -12-')
    right      = cold('     -34|')
    expected   = msgs('---12----')
    left_subs  = [subscribe(200, 4711)]
    right_subs = subs('')

    actual = scheduler.configure(disposed: 4711) { left.concat(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_concat_aborts_on_error
    left       = cold('  -12#')
    right      = cold('     -34|')
    expected   = msgs('---12#')
    left_subs  = subs('  ^  !')
    right_subs = subs('')

    actual = scheduler.configure { left.concat(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_accepts_enumerator
    left       = cold('  -12|')
    right      = cold('     -34|')
    expected   = msgs('---12-34|')
    left_subs  = subs('  ^  !')
    right_subs = subs('     ^  !')

    enum = Enumerator.new do |y|
      y << left
      y << right
    end

    actual = scheduler.configure { Rx::Observable.concat(enum) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_erroring_enumerator
    expected = msgs('--#')
    enum = Enumerator.new do |y|
      raise error
    end

    actual = scheduler.configure { Rx::Observable.concat(enum) }

    assert_msgs expected, actual
  end
end

class TestConcurrencyConcat  < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @observer = Rx::TestScheduler.new.create_observer
  end

  def test_observable_concat_concurrency
    observables = 3.times.map {|n| async_observable(*[on_next(0, "thread-#{n}")] * 3, on_completed(0)) }
    Rx::Observable.concat(*observables).subscribe(@observer)
    await_array_length @observer.messages, 10
    expected = [
      *([on_next(0, 'thread-0')] * 3),
      *([on_next(0, 'thread-1')] * 3),
      *([on_next(0, 'thread-2')] * 3),
      on_completed(0)
    ]
    assert_messages expected, @observer.messages
  end
end
