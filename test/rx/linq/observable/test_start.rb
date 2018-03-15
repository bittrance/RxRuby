require 'test_helper'

class TestOperatorStart < Minitest::Test
  include Rx::MarbleTesting

  def test_return_result_with_context
    expected = msgs('--(a|)')

    context = Struct.new(:result).new('a')
    actual = scheduler.configure do
      Rx::Observable.start(lambda { self.result }, context, scheduler)
    end

    assert_msgs expected, actual
  end
end
