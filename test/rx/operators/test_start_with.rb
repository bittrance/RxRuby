require 'test_helper'

class TestOperatorStartWith < Minitest::Test
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
  end
  
  def test_start_with_prepends_values
    res = @scheduler.configure do
      @left_completing.start_with(0)
    end
    
    expected = [
      on_next(SUBSCRIBED, 0),
      on_next(SUBSCRIBED + 100, 1),
      on_completed(SUBSCRIBED + 200)
    ]
    assert_messages expected, res.messages
  end
  
  def test_start_with_aborts_on_error_right
    res = @scheduler.configure do
      @left_erroring.start_with(0)
    end
    
    expected = [
      on_next(SUBSCRIBED, 0),
      on_next(SUBSCRIBED + 100, 1),
      on_error(SUBSCRIBED + 200, @err)
    ]
    assert_messages expected, res.messages
  end
end