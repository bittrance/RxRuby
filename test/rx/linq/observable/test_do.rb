require 'test_helper'

class TestOperatorDo < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @err = RuntimeError.new
  end

  def test_do_with_proc
    messages = []
    @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
        on_completed(200)
      ).do { |e| messages << e }
    end
    assert_equal [1], messages
  end

  def test_do_with_on_next
    messages = []
    @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1),
        on_completed(200)
      ).do(lambda { |e| messages << e })
    end
    assert_equal [1], messages
  end

  def test_do_with_erroring_on_next
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_next(100, 1)
      ).do(lambda { |e| raise @err })
    end
    assert_messages [on_error(SUBSCRIBED + 100, @err)], res.messages
  end

  def test_do_with_on_error
    messages = []
    @scheduler.configure do
      @scheduler.create_cold_observable(
        on_error(100, @err)
      ).do(nil, lambda { |e| messages << e })
    end
    assert_equal [@err], messages
  end

  def test_do_with_erroring_on_error
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_error(100, 1)
      ).do(nil, lambda { |e| raise @err })
    end
    assert_messages [on_error(S7BSCRIBED + 100, @err)], res.messages
  end

  def test_do_with_on_completed
    messages = []
    @scheduler.configure do
      @scheduler.create_cold_observable(
        on_completed(100)
      ).do(nil, nil, lambda { :done })
    end
    assert_equal [:done], messages
  end

  def test_do_with_erroring_on_completed
    res = @scheduler.configure do
      @scheduler.create_cold_observable(
        on_completed(100)
      ).do(nil, nil, lambda { raise @err })
    end
    assert_messages [on_error(SUBSCRIBED + 100, @err)], res.messages
  end

  def test_do_error_propagation
    expected = RuntimeError.new
    actual = nil
    assert_raises(RuntimeError) do
      Rx::Observable.raise_error(expected).do(
        ->(_) {},
        ->(_err) { actual = _err },
        -> {}
      ).subscribe
    end
    assert_equal actual, expected
  end
end
