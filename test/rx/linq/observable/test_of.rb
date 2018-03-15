require 'test_helper'

class TestObservableOf < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_values
    scheduler = Rx::TestScheduler.new
    actual = scheduler.configure do
      Rx::Observable.of(scheduler, 1, 2)
    end
    expected = [
      on_next(SUBSCRIBED + 1, 1),
      on_next(SUBSCRIBED + 2, 2),
      on_completed(SUBSCRIBED + 3)
    ]
    assert_msgs expected, actual
  end
end
