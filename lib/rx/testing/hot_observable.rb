# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/core/observable'
require 'rx/subscriptions/subscription'
require 'rx/testing/test_subscription'

module Rx

  class HotObservable 
    include Observable

    attr_reader :messages, :subscriptions

    def initialize(scheduler, *args)
      raise 'scheduler cannot be nil' unless scheduler

      @scheduler = scheduler
      @messages = args
      @subscriptions = []
      @observers = []

      @messages.each do |message|
        notification = message.value
        @scheduler.schedule_relative_with_state(nil, message.time, lambda {|scheduler1, state1|

          @observers.clone.each {|observer| notification.accept observer }

          Subscription.empty
        })
      end
    end

    def _subscribe(observer)
      raise 'observer cannot be nil' unless observer

      @observers.push observer
      subscriptions.push (TestSubscription.new @scheduler.now)

      index = subscriptions.length - 1

      Subscription.create do
        @observers.delete observer
        subscriptions[index] = TestSubscription.new(subscriptions[index].subscribe, @scheduler.now)
      end
    end
  end
end
