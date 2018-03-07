require 'test_helper'

class TestCreationDefer < Minitest::Test
  include Rx::MarbleTesting

  def test_defer_complete
    source      = cold('  -1|')
    expected    = msgs('---1|')
    source_subs = subs('  ^ !')

    actual = scheduler.configure do 
      Rx::Observable.defer { source }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source
  end

  def test_defer_error
    source      = cold('  -#')
    expected    = msgs('---#')
    source_subs = subs('  ^!')

    actual = scheduler.configure do 
      Rx::Observable.defer { source }
    end

    assert_msgs expected, actual
    assert_subs source_subs, source     
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
    actual = scheduler.configure do 
      Rx::Observable.defer { raise error }
    end

    assert_msgs msgs('--#'), actual
  end
end