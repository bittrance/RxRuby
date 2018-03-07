require 'test_helper'

class TestCreationEmpty < Minitest::Test
  include Rx::ReactiveTest

  def test_empty_basic
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.empty(scheduler)
    end

    msgs = [on_completed(201)]
    assert_messages msgs, res.messages       
  end

  def test_empty_disposed
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure({:disposed => 200}) do
      Rx::Observable.empty(scheduler)
    end

    msgs = []
    assert_messages msgs, res.messages   
  end

  def test_empty_observer_raises
    scheduler = Rx::TestScheduler.new

    xs = Rx::Observable.empty(scheduler)

    observer = Rx::Observer.configure do |obs|
      obs.on_completed { raise RuntimeError.new }
    end

    xs.subscribe observer

    assert_raises(RuntimeError) { scheduler.start }
  end
end