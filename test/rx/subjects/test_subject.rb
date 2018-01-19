require 'test_helper'

class TestSubject < Minitest::Test
  include Rx::ReactiveTest

  def setup
    @subject = Rx::Subject.new
    @observer1 = Rx::MockObserver.new(scheduler)
    @observer2 = Rx::MockObserver.new(scheduler)
    @err = RuntimeError.new
  end

  def test_subscribe_observer
    @subject.subscribe(@observer1)
    @subject.on_next(1)
    expected = [on_next(0, 1)]
    assert_messages expected, @observer1.messages
  end

  def test_subscribe_block
    messages = []
    @subject.subscribe { |m| messages << m }
    @subject.on_next(1)
    assert_raises(@err.class) do
      @subject.on_error(@err)
    end
    @subject.on_completed
    assert_equal [1], messages
  end

  def subscribe_triple_lambda
    messages = []
    @subject.subscribe(
      lambda { |m| messages << m },
      lambda { |err| messages << err },
      lambda { messages << :complete }
    )
    @subject.on_next(1)
    @subject.on_error(@err)
    @subject.on_completed
    assert_equal [1, @err, :complete], messages
  end

  def test_allows_multiple_subscribers
    @subject.subscribe(@observer1)
    @subject.subscribe(@observer2)
    @subject.on_next(1)
    @subject.on_next(2)
    @subject.on_completed
    expected = [
      on_next(0, 1),
      on_next(0, 2),
      on_completed(0)
    ]
    assert_messages expected, @observer1.messages
    assert_messages expected, @observer2.messages
  end

  def test_subscribe_to_completed_completes
    @subject.on_completed
    @subject.subscribe(@observer1)
    assert_equal [on_completed(0)], @observer1.messages
  end

  def test_subscribe_to_erroring_errors
    @subject.on_error(@err)
    @subject.subscribe(@observer1)
    assert_equal [on_error(0, @err)], @observer1.messages
  end

  def test_unsubscribe_observer_stops_emitting
    s1 = @subject.subscribe(@observer1)
    s2 = @subject.subscribe(@observer2)
    @subject.on_next(1)
    s1.unsubscribe
    @subject.on_next(2)
    assert_messages [on_next(0, 1)], @observer1.messages
    assert_messages [on_next(0, 1), on_next(0, 2)], @observer2.messages
  end

  def test_unsubscribe_disposes_subject
    @subject.unsubscribe
    assert_raises(ArgumentError) do
      @subject.subscribe(@observer1)
    end
    assert_raises(ArgumentError) do
      @subject.on_next(1)
    end
    assert_raises(ArgumentError) do
      @subject.on_error(@err)
    end
    assert_raises(ArgumentError) do
      @subject.on_completed
    end
  end

  def test_unsubscribe_through_autodetach_observer
    subject = Rx::Subject.new
    subject.map {|_| }.subscribe { }
    subject.on_completed
  end
end
