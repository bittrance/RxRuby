require 'test_helper'

class TestAnonymousObservable < Minitest::Test
  include Rx::MarbleTesting

  def test_subscribe_invalid_args_two_lambda
    assert_raises(ArgumentError) do
      Rx::AnonymousObservable.new do |obs|
      end.subscribe(lambda {}, lambda {})
    end
  end

  def test_failure_in_subscribe_block
    observer = scheduler.create_observer
    Rx::AnonymousObservable.new do |obs|
      raise error
    end.subscribe(observer)

    assert_msgs msgs('#'), observer
  end

  def test_failure_after_stopped_in_subscribe_block
    observer = scheduler.create_observer
    assert_raises(error.class) do
      Rx::AnonymousObservable.new do |obs|
        obs.on_completed
        raise error
      end.subscribe(observer)
    end

    assert_msgs msgs('|'), observer
  end
end
