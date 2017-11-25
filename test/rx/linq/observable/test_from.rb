require 'test_helper'

class TestSubject < Minitest::Test
  include Rx::ReactiveTest

  def test_emit_values
    scheduler = Rx::TestScheduler.new
    res = scheduler.configure do
      Rx::Observable.from([1, 2], nil, scheduler)
    end
    expected = [
      on_next(SUBSCRIBED + 1, 1),
      on_next(SUBSCRIBED + 2, 2),
      on_completed(SUBSCRIBED + 3)
    ]
    assert_equal expected, res.messages
  end

  class ErroringEnum
    include Enumerable
    def initialize(err)
      @err = err
    end
    def each
      raise @err
    end
  end

  def test_erroring_enum
    err = RuntimeError.new
    scheduler = Rx::TestScheduler.new
    res = scheduler.configure do
      Rx::Observable.from(ErroringEnum.new(err), nil, scheduler)
    end
    expected = [
      on_error(SUBSCRIBED + 1, err)
    ]
    assert_equal expected, res.messages
  end

  def test_with_map_fn
    scheduler = Rx::TestScheduler.new
    res = scheduler.configure do
      Rx::Observable.from([2, 4], ->(n, i) { n + i }, scheduler)
    end
    expected = [
      on_next(SUBSCRIBED + 1, 2),
      on_next(SUBSCRIBED + 2, 5),
      on_completed(SUBSCRIBED + 3)
    ]
    assert_equal expected, res.messages
  end

  def test_with_erroring_map_fn
    err = RuntimeError.new('badness')
    scheduler = Rx::TestScheduler.new
    res = scheduler.configure do
      Rx::Observable.from([2, 4], ->(n, i) { raise err }, scheduler)
    end
    expected = [
      on_error(SUBSCRIBED + 1, err),
    ]
    assert_equal expected, res.messages
  end
end
