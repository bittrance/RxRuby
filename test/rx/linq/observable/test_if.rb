require "#{File.dirname(__FILE__)}/../../../test_helper"

class TestObservableCreation < Minitest::Test
  include Rx::ReactiveTest

  def test_if
    scheduler = Rx::TestScheduler.new

    called = false
    res = scheduler.configure do
      xs = Rx::Observable.if(
        lambda { called = true; true },
        scheduler.create_cold_observable(
          on_next(100, scheduler.now),
          on_completed(200)
        )
      )
      refute called
      xs
    end

    msgs = [on_next(300, 100), on_completed(400)]
    assert_messages msgs, res.messages
  end

  def test_if_else
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.if(
        lambda { false },
        scheduler.create_cold_observable(on_completed(100)),
        scheduler.create_cold_observable(on_completed(101))
      )
    end

    msgs = [on_completed(301)]
    assert_messages msgs, res.messages
  end

  def test_if_not
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.if(
        lambda { false },
        scheduler.create_cold_observable(on_completed(200))
      )
    end

    msgs = [on_completed(200)]
    assert_messages msgs, res.messages
  end
end
