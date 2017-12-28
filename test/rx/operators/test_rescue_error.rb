require 'test_helper'

class TestOperatorRescueError < Minitest::Test
  include Rx::MarbleTesting

  def test_erroring_left
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')
    actual = scheduler.configure { left.rescue_error(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_erroring_left_with_block
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    actual = scheduler.configure do
      left.rescue_error do |err|
        assert_equal error, err
        right
      end
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_with_erroring_block
    block_error = RuntimeError.new
    left       = cold('  -1#')
    expected   = msgs('---1#', error: block_error)
    left_subs  = subs('  ^ !')

    actual = scheduler.configure do
      left.rescue_error do |err|
        raise block_error
      end
    end

    assert_msgs expected, actual
    assert_subs left_subs, left
  end

  def test_resfuse_right_and_block
    left       = cold('  -#')
    right      = cold('   -1|')
    assert_raises(ArgumentError) do
      left.rescue_error(right) {|_| Rx::Observable.empty() }
    end
  end

  def test_left_completes_so_right_is_not_consulted
    left       = cold('  -1|')
    right      = cold('    -2|')
    expected   = msgs('---1|')
    left_subs  = subs('  ^ !')
    right_subs = subs('     ')
    actual = scheduler.configure { left.rescue_error(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_rescue_error_without_error
    left       = cold('  -1|')
    right      = cold('    -2#')
    expected   = msgs('---1|')
    left_subs  = subs('  ^ !')
    right_subs = subs('     ')
    actual = scheduler.configure { left.rescue_error(right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_empty_source_completes
    actual = scheduler.configure do
      Rx::Observable.rescue_error()
    end
    assert_msgs [on_completed(200)], actual
  end

  def test_observable_rescue_error
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    actual = scheduler.configure { Rx::Observable.rescue_error(left, right) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_accepts_enumerator
    left       = cold('  -1#')
    right      = cold('    -2|')
    expected   = msgs('---1-2|')
    left_subs  = subs('  ^ !')
    right_subs = subs('    ^ !')

    enum = Enumerator.new do |y|
      y << left
      y << right
    end

    actual = scheduler.configure { Rx::Observable.rescue_error(enum) }

    assert_msgs expected, actual
    assert_subs left_subs, left
    assert_subs right_subs, right
  end

  def test_erroring_enumerator
    enum = Enumerator.new do |y|
      raise error
    end

    actual = scheduler.configure do
      Rx::Observable.rescue_error(enum)
    end

    expected = msgs('--#')
    assert_msgs expected, actual
  end

  def test_disposing_stops_enumeration
    erroring      = cold('-#')
    erroring_subs = subs('  ^(!^)!')
    enum = Enumerator.new do |y|
      y << erroring while true
    end

    scheduler.configure(disposed: 400) do
      Rx::Observable.rescue_error(enum)
    end

    assert_subs erroring_subs, erroring
  end
end

class TestRescueErrorConcurrency < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
  end

  def test_observable_rescue_error_concurrent
    sentinel_called = false
    observables = [
      async_observable(
        on_next(0, 1),
        on_error(0, @err)
      ),
      async_observable(
        *([on_next(0, 2)] * 3),
        on_completed(0)
      ),
      async_observable(
        on_error(0, @err)
      ).do { sentinel_called = true }
    ]
    Rx::Observable.rescue_error(*observables)
      .subscribe(@observer)
    await_array_length(@observer.messages, 5)
    assert_equal false, sentinel_called
    expected = [
      on_next(0, 1),
      *[on_next(0, 2)] * 3,
      on_completed(0)
    ]
    assert_messages expected, @observer.messages
  end
end
