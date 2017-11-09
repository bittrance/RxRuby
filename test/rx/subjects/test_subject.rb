require 'test_helper'

class TestBehaviorSubject < Minitest::Test
  def test_unsubscribe_through_autodetach_observer
    subject = Rx::Subject.new
    subject.map {|_| }.subscribe { }
    subject.on_completed
  end
end
