require 'test_helper'

class TestCreationFromArray < Minitest::Test
  include Rx::ReactiveTest

  def test_from_array_empty
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.from_array([], scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_simple
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.from_array([1, 2, 3], scheduler)
    end

    msgs = [
        on_next(201, 1),
        on_next(202, 2),
        on_next(203, 3),
        on_completed(204)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_complex_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 204) do
      Rx::Observable.from_array([[], [[]], [[[]]], [[[[]]]]], scheduler)
    end

    msgs = [
        on_next(201, []),
        on_next(202, [[]]),
        on_next(203, [[[]]])
    ]
    assert_messages msgs, res.messages
  end
end