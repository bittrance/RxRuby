require 'test_helper'

class TestOperatorIf < Minitest::Test
  include Rx::MarbleTesting

  def test_if
    actual = scheduler.configure do
      Rx::Observable.if(
        lambda { true },  cold('-1|'), cold('2|')
      )
    end

    assert_msgs msgs('---1|'), actual
  end

  def test_if_else
    actual = scheduler.configure do
      Rx::Observable.if(
        lambda { false }, cold('-1|'), cold('2|')
      )
    end

    assert_msgs msgs('--2|'), actual
  end

  def test_if_not
    actual = scheduler.configure do
      Rx::Observable.if(
        lambda { false }, cold('-1|')
      )
    end

    assert_msgs msgs('--|'), actual
  end

  def test_raises
    actual = scheduler.configure do
      Rx::Observable.if(
        lambda { raise error }, cold('-1|')
      )
    end

    assert_msgs msgs('--#'), actual
  end
end
