require 'test_helper'

class TestOperatorAmb < Minitest::Test
  include Rx::MarbleTesting

  def test_left_on_next_wins
    left       = cold('  -1---|')
    right      = cold('  --2-|')
    expected   = msgs('---1---|')
    left_subs  = subs('  ^    !')
    right_subs = subs('  ^!')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_left_on_error_wins
    left       = cold('  -#')
    right      = cold('  --2-|')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^!')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_left_on_completed_wins
    left       = cold('  -|')
    right      = cold('  --2-|')
    expected   = msgs('---|')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^!')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_right_on_next_wins
    left       = cold('  --2-|')
    right      = cold('  -1---|')
    expected   = msgs('---1---|')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^    !')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_right_on_error_wins
    left       = cold('  --2-|')
    right      = cold('  -#')
    expected   = msgs('---#')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^!')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_right_on_completed_wins
    left       = cold('  --2-|')
    right      = cold('  -|')
    expected   = msgs('---|')
    left_subs  = subs('  ^!')
    right_subs = subs('  ^!')

    actual = scheduler.configure { left.amb(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def setup
    @scheduler = Rx::TestScheduler.new
  end
end

class TestConcurrencyAmb  < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @observer = Rx::TestScheduler.new.create_observer
  end

  def test_amb_concurrency
    left = async_observable(*[on_next(100, :left)] * 3)
    right = async_observable(*[on_next(100, :right)] * 3)
    left.amb(right).subscribe(@observer)
    await_array_minimum_length(@observer.messages, 3)
    types = @observer.messages.select {|m| m.value.on_next? }.map {|m| m.value.value }.uniq
    assert_equal 1, types.size # i.e. there should not be both :left and :right
  end

  def test_observable_amb_concurrency
    observables = 10.times.map { |n| async_observable(*[on_next(100, "thread-#{n}")] * 3) }
    Rx::Observable.amb(*observables).subscribe(@observer)
    await_array_minimum_length(@observer.messages, 3)
    types = @observer.messages.select {|m| m.value.on_next? }.map {|m| m.value.value }.uniq
    assert_equal 1, types.size
  end
end
