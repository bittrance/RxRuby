require 'test_helper'

class TestConnectableObservable < Minitest::Test
  include Rx::MarbleTesting

  def setup
    @observer = scheduler.create_observer
    @subject1 = Rx::Subject.new
    @subject1_observer = scheduler.create_observer
    @subject1.subscribe(@subject1_observer)
  end

  def test_no_values_without_connect
    source = cold('1-2|')
    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    scheduler.advance_to(700)
    assert_msgs [], @observer
    assert_msgs [], @subject1_observer
    assert_subs [], source
  end

  def test_subscribe_to_source_on_connect
    source = cold('1-2|')
    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    scheduler.advance_to(300)
    connectable.connect
    scheduler.advance_to(700)
    assert_msgs msgs('---1-2|'), @observer
    assert_msgs msgs('---1-2|'), @subject1_observer
    assert_subs subs('---^--!'), source
  end

  def test_reconnection
    source = hot('1-2-3-4-5|')
    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    s1 = connectable.connect
    scheduler.advance_to(300)
    s1.unsubscribe
    scheduler.advance_to(500)
    connectable.connect
    scheduler.advance_to(900)
    assert_msgs msgs('1-2---4-5|'), @observer
    assert_msgs msgs('1-2---4-5|'), @subject1_observer
    assert_subs subs('^--!-^---!'), source
  end

  def test_propagates_error
    source = cold('-#')
    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    connectable.connect
    scheduler.advance_to(700)
    assert_msgs msgs('-#'), @observer
    assert_msgs msgs('-#'), @subject1_observer
    assert_subs subs('^!'), source
  end

  def test_ref_counting
    source = cold('123456')

    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    counter = connectable.ref_count
    o1 = scheduler.create_observer
    s1 = counter.subscribe(o1)
    scheduler.advance_to(99)
    o2 = scheduler.create_observer
    s2 = counter.subscribe(o2)
    scheduler.advance_to(200)
    s1.unsubscribe
    scheduler.advance_to(300)
    s2.unsubscribe
    scheduler.advance_to(700)

    assert_msgs msgs('1234'), @observer
    assert_msgs msgs('1234'), @subject1_observer
    assert_msgs msgs('123-'), o1
    assert_msgs msgs('-234'), o2
    assert_subs subs('^  !'), source
  end

  def test_ref_counting_not_affected_by_unsubscribe
    source = cold('1234')

    connectable = Rx::ConnectableObservable.new(source, @subject1)
    s1 = connectable.subscribe(@observer)
    counter = connectable.ref_count
    o1 = scheduler.create_observer
    counter.subscribe(o1)
    scheduler.advance_to(100)
    s1.unsubscribe
    scheduler.advance_to(700)

    assert_msgs msgs('1234'), o1
  end

  def test_ref_counting_propagates_error
    source = cold('-#')

    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.subscribe(@observer)
    counter = connectable.ref_count
    o1 = scheduler.create_observer
    counter.subscribe(o1)
    scheduler.advance_to(200)

    assert_msgs msgs('-#'), @observer
    assert_msgs msgs('-#'), o1
    assert_subs subs('^!'), source
  end

  def test_ref_counting_fails_when_connected
    source = cold('-#')

    connectable = Rx::ConnectableObservable.new(source, @subject1)
    connectable.connect
    assert_raises(RuntimeError) do
      connectable.ref_count
    end
  end
end
