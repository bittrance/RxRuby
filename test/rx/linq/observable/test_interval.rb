require 'test_helper'

class TestOperatorInterval < Minitest::Test
  include Rx::MarbleTesting

  def test_emit_value_every_interval
    expected = msgs('-----0--1--')
    actual = scheduler.configure do
      Rx::Observable.interval(300, scheduler)
    end

    assert_msgs expected, actual
  end
end