require 'test_helper'
require 'rx/subjects/helpers/test_observer_mock'

module Rx
  class TestAsyncSubject < Minitest::Test
    def setup
      @observer = TestObserverMock.new
      @subject = Rx::AsyncSubject.new
    end

    def test_receive_last_value_on_completion
      @subject.subscribe(@observer)
      @subject.on_next(1)
      @subject.on_next(2)
      assert_equal([], @observer.next)
      @subject.on_completed
      assert_equal(true, @observer.completed)
      assert_equal([2], @observer.next)
    end

    def test_receive_previous_error_on_late_subscribe
      @subject.on_error('badness')
      @subject.subscribe(@observer)
      assert_equal('badness', @observer.error)
    end
  end
end
