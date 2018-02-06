# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestBehaviorSubject < Minitest::Test
  include Rx::ReactiveTest

  class MyError < RuntimeError ; end

  def setup
    @subject = Rx::BehaviorSubject.new(42)
    @observer1 = Rx::MockObserver.new(scheduler)
    @observer2 = Rx::MockObserver.new(scheduler)
    @err = MyError.new
  end

  def test_subscribe_with_observer
    @subject.subscribe(@observer1)
    expected = [on_next(0, 42)]
    assert_messages expected, @observer1.messages
  end

  def test_subscribe_with_block
    messages = []
    @subject.subscribe { |m| messages << m }
    assert_equal [42], messages
  end

  def test_subscribe_with_triple_lambda_value
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    assert_equal [42], messages
  end

  def test_subscribe_with_triple_lambda_error
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    @subject.on_error(@err)
    assert_equal [42, @err], messages
  end

  def test_subscribe_with_triple_lambda_completed
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    @subject.on_completed
    assert_equal [42, :complete], messages
  end

  def test_subscriber_notified_on_change
    value = nil
    @subject.subscribe { |update| value = update }
    assert_equal 42, value
    @subject.on_next 43
    assert_equal 43, value
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

  def test_exposes_current_value
    assert_equal 42, @subject.value
    @subject.on_next 43
    assert_equal 43, @subject.value
  end

  def test_current_value_raises_error_on_error
    @subject.on_error @err
    assert_raises(MyError) { @subject.value }
  end

  def test_current_value_raises_when_disposed
    @subject.unsubscribe
    assert_raises(RuntimeError) { @subject.value }
  end

  def test_emit_latest_value_on_subscribe
    value = nil
    @subject.on_next 43
    @subject.subscribe { |update| value = update }
    assert_equal 43, value
  end

  def test_emit_error_on_subscribe
    messages = []
    @subject.on_error(@err)
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    assert_equal [@err], messages
  end

  def test_emit_completion_on_subscribe
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
    assert_equal 43, value1
    assert_equal 43, value2
  end

  def test_ignore_error_after_completed
    @subject.subscribe(@observer1)
    @subject.on_completed
    @subject.on_error(@err)
    expected = [on_next(0, 42), on_completed(0)]
    assert_messages expected, @observer1.messages
  end

  def test_ignore_completed_after_error
    @subject.subscribe(@observer1)
    @subject.on_error(@err)
    @subject.on_completed
    expected = [on_next(0, 42), on_error(0, @err)]
    assert_messages expected, @observer1.messages
  end

  def test_unsubscribe_observer_stops_emitting
    s1 = @subject.subscribe(@observer1)
    s2 = @subject.subscribe(@observer2)
    s1.unsubscribe
    @subject.on_next(43)
    assert_messages [on_next(0, 42)], @observer1.messages
    assert_messages [on_next(0, 42), on_next(0, 43)], @observer2.messages
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
end
