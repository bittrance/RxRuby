require 'test_helper'

class TestCreationDefer < Minitest::Test
  include Rx::MarbleTesting

  def test_defer_complete
    scheduler = Rx::TestScheduler.new 

    invoked = 0
    xs = nil

    res = scheduler.configure do 
      Rx::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.now),
          on_completed(200)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_completed(400)]
    assert_messages msgs, res.messages

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 400)], xs.subscriptions
  end

  def test_defer_error
    scheduler = Rx::TestScheduler.new

    invoked = 0
    xs = nil
    err = RuntimeError.new

    res = scheduler.configure do
      Rx::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.now),
          on_error(200, err)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_error(400, err)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 400)], xs.subscriptions     
  end

  def test_defer_unsubscribe
    scheduler = Rx::TestScheduler.new

    invoked = 0
    xs = nil

    res = scheduler.configure do
      Rx::Observable.defer do
        invoked += 1

        xs = scheduler.create_cold_observable(
          on_next(100, scheduler.now),
          on_next(200, invoked),
          on_next(1100, 1000)
        )
        xs
      end
    end

    msgs = [on_next(300, 200), on_next(400, 1)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked

    assert_subscriptions [subscribe(200, 1000)], xs.subscriptions     
  end

  def test_defer_raise
    scheduler = Rx::TestScheduler.new 

    invoked = 0
    err = RuntimeError.new

    res = scheduler.configure do 
      Rx::Observable.defer do
        invoked += 1
        raise err
      end
    end

    msgs = [on_error(200, err)]
    assert_messages msgs, res.messages    

    assert_equal 1, invoked     
  end
end