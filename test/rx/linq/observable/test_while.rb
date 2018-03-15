require 'test_helper'

class TestObservableWhile < Minitest::Test
  include Rx::MarbleTesting

  def test_condition_completes
    i = 0
    source = cold('1-2|')
    actual = scheduler.configure do
      Rx::Observable.while(lambda { (i += 1) < 3 }, source)
    end

    assert_msgs msgs('--1-21-2|'), actual
    assert_subs subs('--^--(!^)--!'), source
    assert_equal i, 3
  end

  def test_unsubscribe_while_emitting
    observer = scheduler.create_observer
    s1 = Rx::Observable.while(
      lambda { true },
      cold('1-2|')
    ).subscribe(observer)
    scheduler.advance_to(400)
    s1.unsubscribe
    scheduler.advance_to(600)

    assert_msgs msgs('1-21-'), observer
  end

  def test_break_on_error
    source      = cold('  #')
    source_subs = subs('  (^!)')
    i = 0
    actual = scheduler.configure do
      Rx::Observable.while(lambda { (i += 1) < 3 }, source)
    end

    assert_msgs msgs('--#'), actual
    assert_subs source_subs, source
  end

  def test_erroring_condition
    source      = cold('  1')

    actual = scheduler.configure do
      Rx::Observable.while(lambda { raise error }, source)
    end
    assert_msgs msgs('--#'), actual
    assert_subs [], source
  end
end
