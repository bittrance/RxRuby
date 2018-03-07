# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require "#{File.dirname(__FILE__)}/../../test_helper"

class TestObservableCreation < Minitest::Test
  include Rx::ReactiveTest

  # Empty methods

  def test_empty_basic
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.empty(scheduler)
    end

    msgs = [on_completed(201)]
    assert_messages msgs, res.messages       
  end

  def test_empty_disposed
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure({:disposed => 200}) do
      Rx::Observable.empty(scheduler)
    end

    msgs = []
    assert_messages msgs, res.messages   
  end

  def test_empty_observer_raises
    scheduler = Rx::TestScheduler.new

    xs = Rx::Observable.empty(scheduler)

    observer = Rx::Observer.configure do |obs|
      obs.on_completed { raise RuntimeError.new }
    end

    xs.subscribe observer

    assert_raises(RuntimeError) { scheduler.start }
  end

  # Never methods

  def test_never_basic
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.never
    end

    msgs = []
    assert_messages msgs, res.messages
  end

  # Repeat methods
=begin
# the clock is actually off, because of not using the `scheduler.schedule_recursive`
  def test_repeat_value_count_zero
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.repeat(42, 0, scheduler)
    end

    msgs = [
      on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_repeat_value_once
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.repeat(42, 1, scheduler)
    end

    msgs = [
        on_next(201, 42),
        on_completed(202)
    ]
    assert_messages msgs, res.messages
  end
=end

  def test_repeat_infinitely_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 203) do
      Rx::Observable.repeat_infinitely({a: 1}, scheduler)
    end

    msgs = [
        on_next(201, {a: 1}),
        on_next(202, {a: 1})
    ]
    assert_messages msgs, res.messages
  end

  # from_array methods
  def test_from_array_empty
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.from_array([], scheduler)
    end

    msgs = [
        on_completed(201)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_simple
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure do
      Rx::Observable.from_array([1, 2, 3], scheduler)
    end

    msgs = [
        on_next(201, 1),
        on_next(202, 2),
        on_next(203, 3),
        on_completed(204)
    ]
    assert_messages msgs, res.messages
  end

  def test_from_array_complex_dispose
    scheduler = Rx::TestScheduler.new

    res = scheduler.configure(:disposed => 204) do
      Rx::Observable.from_array([[], [[]], [[[]]], [[[[]]]]], scheduler)
    end

    msgs = [
        on_next(201, []),
        on_next(202, [[]]),
        on_next(203, [[[]]])
    ]
    assert_messages msgs, res.messages
  end
end
