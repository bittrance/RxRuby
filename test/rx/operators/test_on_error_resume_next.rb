require 'test_helper'

class TestOperatorOnErrorResumeNext < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
    @observer = @scheduler.create_observer
    @err = RuntimeError.new
    @left_completing = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_completed(200)
    )
    @left_erroring = @scheduler.create_cold_observable(
      on_next(100, 1),
      on_error(200, @err)
    )
    @right_completing = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_completed(200)
    )
    @right_erroring = @scheduler.create_cold_observable(
      on_next(100, 2),
      on_error(200, @err)
    )
  end

  def test_resumes_next_on_left_error
    res = @scheduler.configure do
      @left_erroring.on_error_resume_next(@right_completing)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_completes_on_right_error
    res = @scheduler.configure do
      @left_completing.on_error_resume_next(@right_erroring)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_resumes_next_continues_on_complete
    res = @scheduler.configure do
      @left_completing.on_error_resume_next(@right_completing)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_subscribes_right_late
    @scheduler.configure do
      @left_completing.on_error_resume_next(@right_completing)
    end

    expected = [
      subscribe(SUBSCRIBED, SUBSCRIBED + 200)
    ]
    assert_subscriptions expected, @left_completing.subscriptions
    expected = [
      subscribe(SUBSCRIBED + 200, SUBSCRIBED + 400)
    ]
    assert_subscriptions expected, @right_completing.subscriptions
  end

  def test_right_cannot_be_nil
    assert_raises(ArgumentError) do
      @left_completing.on_error_resume_next(nil)
    end
  end

  def test_accepts_enumerator
    enum = Enumerator.new do |y|
      y << @left_erroring
      y << @right_completing
    end

    res = @scheduler.configure do
      Rx::Observable.on_error_resume_next(enum)
    end

    expected = [
      on_next(SUBSCRIBED + 100, 1),
      on_next(SUBSCRIBED + 300, 2),
      on_completed(SUBSCRIBED + 400)
    ]
    assert_messages expected, res.messages
  end

  def test_erroring_enumerator
    enum = Enumerator.new do |y|
      raise @err
    end

    res = @scheduler.configure do
      Rx::Observable.on_error_resume_next(enum)
    end

    expected = [
      on_error(SUBSCRIBED, @err)
    ]
    assert_messages expected, res.messages
  end
end
