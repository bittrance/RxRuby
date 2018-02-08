require 'test_helper'

class TestAsyncSubject < Minitest::Test
  include Rx::ReactiveTest

  class MyError < RuntimeError ; end

  def setup
    @subject = Rx::AsyncSubject.new
    @observer1 = Rx::MockObserver.new(scheduler)
    @observer2 = Rx::MockObserver.new(scheduler)
    @err = MyError.new
  end

  def test_subscribe_with_observer
    @subject.subscribe(@observer1)
    @subject.on_completed
    expected = [on_completed(0)]
    assert_messages expected, @observer1.messages
  end

  def test_subscribe_with_block
    messages = []
    @subject.subscribe { |m| messages << m }
    @subject.on_next(42)
    @subject.on_completed
    assert_equal [42], messages
  end

  def test_subscribe_with_triple_lambda_value
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    @subject.on_next(42)
    @subject.on_completed
    assert_equal [42, :complete], messages
  end

  def test_subscribe_with_triple_lambda_error
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    @subject.on_error(@err)
    assert_equal [@err], messages
  end

  def test_has_observers
    assert_equal false, @subject.has_observers?
    s = @subject.subscribe { }
    assert_equal true, @subject.has_observers?
    s.unsubscribe
    assert_equal false, @subject.has_observers?
    @subject.subscribe { }
    assert_equal true, @subject.has_observers?
    @subject.unsubscribe
    assert_equal false, @subject.has_observers?
  end

  def test_subscriber_not_notified_on_change
    value = nil
    @subject.subscribe { |update| value = update }
    assert_nil value
    @subject.on_next 43
    assert_nil value
  end

  def test_emit_last_value_on_complete
    value = nil
    @subject.subscribe { |update| value = update }
    @subject.on_next 42
    @subject.on_next 43
    @subject.on_completed
    assert_equal 43, value
  end

  def test_late_subscriber_gets_last_value
    value = nil
    @subject.on_next 43
    @subject.on_completed
    @subject.subscribe { |update| value = update }    
    assert_equal 43, value
  end

  def test_late_subscriber_gets_error
    messages = []
    @subject.on_error(@err)
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    assert_equal [@err], messages
  end

  def test_late_subscriber_gets_on_completed
    messages = []
    @subject.on_completed
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    assert_equal [:complete], messages
  end

  def test_multiple_observers_notified_on_change
    value1 = nil
    value2 = nil
    @subject.subscribe { |update| value1 = update }
    @subject.subscribe { |update| value2 = update }
    @subject.on_next 43
    @subject.on_completed
    assert_equal 43, value1
    assert_equal 43, value2
  end

  def test_ignores_error_after_completed
    @subject.subscribe(@observer1)
    @subject.on_completed
    @subject.on_error(@err)
    expected = [on_completed(0)]
    assert_messages expected, @observer1.messages
  end

  def test_ignores_completed_after_error
    @subject.subscribe(@observer1)
    @subject.on_error(@err)
    @subject.on_completed
    expected = [on_error(0, @err)]
    assert_messages expected, @observer1.messages
  end

  def test_unsubscribe_observer_stops_emitting
    s1 = @subject.subscribe(@observer1)
    @subject.subscribe(@observer2)
    s1.unsubscribe
    @subject.on_next(43)
    @subject.on_completed
    assert_messages [], @observer1.messages
    assert_messages [on_next(0, 43), on_completed(0)], @observer2.messages
  end

  def test_disposed_subject_refuses_all_interaction
    @subject.unsubscribe
    assert_raises(RuntimeError) do
      @subject.subscribe(@observer1)
    end
    assert_raises(RuntimeError) do
      @subject.on_next(1)
    end
    assert_raises(RuntimeError) do
      @subject.on_error(@err)
    end
    assert_raises(RuntimeError) do
      @subject.on_completed
    end
  end

  def test_errors_on_next_when_unsubscribed
    @subject.subscribe { }
    @subject.unsubscribe
    assert_raises(RuntimeError) { @subject.on_next 1 }
  end
end
