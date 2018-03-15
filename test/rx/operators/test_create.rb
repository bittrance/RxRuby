require 'test_helper'

class TestCreationCreate < Minitest::Test
  include Rx::MarbleTesting

  def test_create_completed
    res = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_completed
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end

    assert_messages [on_completed(200)], res.messages
  end

  def test_create_error
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_error error
        obs.on_next 100
        obs.on_error RuntimeError.new
        obs.on_completed
        nil
      end
    end

    assert_messages [on_error(200, error)], res.messages
  end

  def test_raises_on_erroring_observer_on_next
    assert_raises(MyError) do
      observable = Rx::Observable.create do |obs|
        obs.on_next 1
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_next { |x| raise error }
      end

      observable.subscribe observer
    end
  end

  def test_raises_on_erroring_observer_on_error
    assert_raises(MyError) do
      observable = Rx::Observable.create do |obs|
        obs.on_error RuntimeError.new
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_error { |err| raise error }
      end

      observable.subscribe observer
    end
  end

  def test_raises_on_erroring_observer_on_completed
    assert_raises(MyError) do
      observable = Rx::Observable.create do |obs|
        obs.on_completed
        nil
      end

      observer = Rx::Observer.configure do |o|
        o.on_completed { raise error }
      end

      observable.subscribe observer
    end
  end

  def test_create_next_return_subscription
    unsubscribed = false
    actual = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        Rx::Subscription.create { unsubscribed = true }
      end
    end

    assert_msgs msgs('--(12)'), actual
    assert true, unsubscribed
  end

  def test_create_next_return_nil
    actual = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        nil
      end
    end

    assert_msgs msgs('--(12)'), actual
  end

  def test_create_with_unsubscribe_action
    disposed = false
    scheduler.configure do
      Rx::Observable.create do |obs|
        lambda { disposed = scheduler.now }
      end
    end
    assert_equal 1000, disposed
  end
end
