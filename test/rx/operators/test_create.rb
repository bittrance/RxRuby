require 'test_helper'

class TestCreationCreate < Minitest::Test
  include Rx::MarbleTesting

  def test_create_next_return_subscription
    actual = scheduler.configure do
      Rx::Observable.create do |obs|
        obs.on_next 1
        obs.on_next 2
        Rx::Subscription.empty
      end
    end

    assert_msgs msgs('--(12)'), actual
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
