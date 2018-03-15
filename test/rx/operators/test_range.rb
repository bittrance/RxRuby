require 'test_helper'

class TestCreationRange < Minitest::Test
  include Rx::ReactiveTest

  def test_range_zero
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.range(0, 0, scheduler)
    end

    msgs = [on_completed(201)]
    assert_messages msgs, res.messages    
  end

  def test_range_one
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.range(0, 1, scheduler)
    end

    msgs = [on_next(201, 0), on_completed(202)]
    assert_messages msgs, res.messages      
  end

  def test_range_five
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.range(10, 5, scheduler)
    end

    msgs = [
      on_next(201, 10),
      on_next(202, 11),
      on_next(203, 12),
      on_next(204, 13),
      on_next(205, 14),
      on_completed(206)
    ]
    assert_messages msgs, res.messages      
  end

  def test_range_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 204) do
      Rx::Observable.range(-10, 5, scheduler)
    end

    msgs = [
      on_next(201, -10),
      on_next(202, -9),
      on_next(203, -8),
    ]
    assert_messages msgs, res.messages 
  end
end