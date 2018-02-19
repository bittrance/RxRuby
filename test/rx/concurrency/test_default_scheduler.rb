# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'test_helper'

class TestDefaultScheduler < Minitest::Test
  include Rx::AsyncTesting

  def setup
    @scheduler = Rx::DefaultScheduler.instance
  end

  def test_schedule_with_state
    state = []
    task  = ->(_, s) { s << 1 }
    @scheduler.schedule_with_state(state, task)
    await_array_length(state, 1)

    assert_equal([1], state)
  end

  def test_schedule_relative_with_state
    state = []
    task  = ->(_, s) { s << 1 }
    @scheduler.schedule_relative_with_state(state, 0.05, task)
    await_array_length(state, 1, 0.09)

    assert_equal([1], state)
  end

  def test_default_schedule_runs_in_its_own_thread
    state = []
    id = Thread.current.object_id
    @scheduler.schedule -> { state << Thread.current.object_id }
    await_array_length(state, 1)

    refute_equal([id], state)
  end

  def test_schedule_recursive_absolute_non_recursive
    task = ->(a) { a.call(Time.now) }

    subscription = @scheduler.schedule_recursive_absolute(Time.now, task)
    await_criteria(2) { subscription.subscription && subscription.subscription.length == 1 }
    subscription.unsubscribe
  end

  def test_schedule_action_cancel
    task = -> { flunk "This should not run." }
    subscription = @scheduler.schedule_relative(0.05, task)
    subscription.unsubscribe
    sleep 0.1
  end
end
