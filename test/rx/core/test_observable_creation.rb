# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require "#{File.dirname(__FILE__)}/../../test_helper"

class TestObservableCreation < Minitest::Test
  include Rx::ReactiveTest

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
end
