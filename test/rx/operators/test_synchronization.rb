# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require "#{File.dirname(__FILE__)}/../../test_helper"

class TestObservableSynchronization < Minitest::Test
  include Rx::AsyncTesting
  include Rx::ReactiveTest

  def setup
    @scheduler = Rx::TestScheduler.new
  end

  def test_subscribe_on
    mock = Rx::MockObserver.new @scheduler
    Rx::Observable.just(1)
      .subscribe_on(@scheduler)
      .subscribe(mock)
    assert_equal 0, mock.messages.length
    @scheduler.advance_by 100
    assert_equal 2, mock.messages.length
  end

  def test_subscribe_on_default_scheduler_does_not_raise
    Rx::Observable.just(1).subscribe_on(Rx::DefaultScheduler.instance).subscribe
  end

  def test_subscribe_on_current_thread_scheduiler_does_not_raise
    Rx::Observable.just(1).subscribe_on(Rx::CurrentThreadScheduler.instance).subscribe
  end

  def test_subscribe_on_default_scheduler_with_merge_all
    observer = @scheduler.create_observer
    Rx::Observable.of(Rx::Observable.from([1, 2, 3]), Rx::Observable.from([4, 5, 6]))
      .subscribe_on(Rx::DefaultScheduler.instance)
      .merge_all
      .subscribe(observer)

    await_array_length(observer.messages, 7, 4)

    expected = [
      on_next(0, 1),
      on_next(0, 2),
      on_next(0, 4),
      on_next(0, 3),
      on_next(0, 5),
      on_next(0, 6),
      on_completed(0)
    ]
    assert_messages expected, observer.messages
  end
end
