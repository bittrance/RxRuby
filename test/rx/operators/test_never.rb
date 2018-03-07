require 'test_helper'

class TestCreationEmpty < Minitest::Test
  include Rx::ReactiveTest

  def test_never
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.never
    end

    msgs = []
    assert_messages msgs, res.messages
  end
end