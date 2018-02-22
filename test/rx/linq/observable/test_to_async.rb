require 'test_helper'

class TestOperatorToAsync < Minitest::Test
  include Rx::MarbleTesting

  def test_return_result
    expected = msgs('--(1|)')

    actual = scheduler.configure do
      Rx::Observable.to_async(lambda { 1 }, nil, scheduler).call
    end

    assert_msgs expected, actual
  end

  def test_call_with_arguments
    expected = msgs('--(2|)')

    actual = scheduler.configure do
      Rx::Observable.to_async(lambda { |x| x }, nil, scheduler).call(2)
    end

    assert_msgs expected, actual
  end

  def test_return_result_with_context
    expected = msgs('--(a|)')

    context = Struct.new(:result).new('a')
    actual = scheduler.configure do
      Rx::Observable.to_async(lambda { self.result }, context, scheduler).call
    end

    assert_msgs expected, actual
  end

  def test_propagates_error
    expected = msgs('--#')

    actual = scheduler.configure do
      Rx::Observable.to_async(lambda { raise error }, nil, scheduler).call
    end

    assert_msgs expected, actual
  end
end