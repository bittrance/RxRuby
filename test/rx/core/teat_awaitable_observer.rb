require 'test_helper'

class TestAwaitableObserver < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @awaitable = Rx::AwaitableObserver.new
    @awaitable.subscription = Rx::Subscription.create {}
  end

  def test_unblocks_on_unsubscribe
    actual = []
    Thread.new do
      sleep 0.1
      actual << :unsubscribe
      @awaitable.unsubscribe
    end
    assert_equal true, @awaitable.await(1)
    actual << :unblock
    assert_equal [:unsubscribe, :unblock], actual
  end
  
  def test_returns_false_on_timeout
    assert_equal false, @awaitable.await(0)
  end
  
  def test_awaiting_unsubscribed_raises
    awaitable = Rx::AwaitableSubscription.new
    assert_raises(RuntimeError) do
      awaitable.await(0)
    end
  end
end
