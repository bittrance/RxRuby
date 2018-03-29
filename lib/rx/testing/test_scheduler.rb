# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/virtual_time_scheduler'
require 'rx/subscriptions/subscription'
require 'rx/testing/cold_observable'
require 'rx/testing/hot_observable'
require 'rx/testing/mock_observer'
require 'rx/testing/reactive_test'

module Rx

  # Virtual time scheduler used for testing applications and libraries built using Reactive Extensions.
  class TestScheduler < VirtualTimeScheduler

    def initialize(increment_on_simultaneous = true)
      @increment_on_simultaneous = increment_on_simultaneous
      super(0)
    end

    # Schedules an action to be executed at due_time.
    def schedule_absolute_with_state(state, due_time, action)
      raise 'action cannot be nil' unless action

      due_time = now + 1 if due_time <= now && @increment_on_simultaneous

      super(state, due_time, action)
    end

    # Starts the test scheduler and uses the specified virtual times to invoke the factory function, subscribe to the resulting sequence, and unsubscribe the subscription.
    def configure(options = {})
      options.each {|key,_|
        unless [:created, :subscribed, :disposed].include? key
          raise ArgumentError, "Should be specified whether :created, :subscribed or :disposed, but the #{key.inspect}"
        end
      }
      o = {
        :created    => ReactiveTest::CREATED,
        :subscribed => ReactiveTest::SUBSCRIBED,
        :disposed   => ReactiveTest::DISPOSED
      }.merge(options)

      source = nil
      subscription = nil
      observer = create_observer

      schedule_absolute_with_state(nil, o[:created], lambda {|scheduler, state|
        source = yield
        Subscription.empty
      })

      schedule_absolute_with_state(nil, o[:subscribed], lambda {|scheduler, state|
        subscription = source.subscribe observer
        Subscription.empty
      })

       schedule_absolute_with_state(nil, o[:disposed], lambda {|scheduler, state|
        subscription.unsubscribe
        Subscription.empty
      })

      start

      observer
    end

    # Creates a hot observable using the specified timestamped notification messages.
    def create_hot_observable(*args)
      HotObservable.new(self, *args)
    end

    # Creates a cold observable using the specified timestamped notification messages.
    def create_cold_observable(*args)
      ColdObservable.new(self, *args)
    end

    # Creates an observer that records received notification messages and timestamps those.
    def create_observer
      MockObserver.new self
    end

  end
end
