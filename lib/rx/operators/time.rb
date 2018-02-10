# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'thread'
require 'rx/concurrency/default_scheduler'
require 'rx/subscriptions/subscription'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/ref_count_subscription'
require 'rx/subscriptions/serial_subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/subjects/subject'


module Rx

  # Time based operations
  module Observable

    # Projects each element of an observable sequence into consecutive non-overlapping buffers which are produced
    # based on timing information.
    def buffer_with_time(time_span, time_shift = time_span, scheduler = DefaultScheduler.instance)
      raise ArgumentError.new 'time_span must be greater than zero' if time_span <= 0
      raise ArgumentError.new 'time_span must be greater than zero' if time_shift <= 0
      window_with_time(time_span, time_shift, scheduler).flat_map(&:to_a)
    end

    # Projects each element of an observable sequence into consecutive non-overlapping windows which are produced
    # based on timing information.
    def window_with_time(time_span, time_shift = time_span, scheduler = DefaultScheduler.instance)
      raise ArgumentError.new 'time_span must be greater than zero' if time_span <= 0
      raise ArgumentError.new 'time_span must be greater than zero' if time_shift <= 0

      AnonymousObservable.new do |observer|
        q = []
        stopped = false
        gate = Monitor.new

        start_sub = SerialSubscription.new
        close_subs = CompositeSubscription.new

        start_window = lambda do
          gate.synchronize do
            unless stopped
              if time_span == time_shift
                window = gate.synchronize { q.shift unless stopped }
                window.on_completed if window
              else
                m = SingleAssignmentSubscription.new
                close_subs << m
                m.subscription = scheduler.schedule_relative(time_span, lambda do
                  window = gate.synchronize { q.shift unless stopped }
                  window.on_completed if window
                  close_subs.delete(m)
                end)
              end
              window = Subject.new
              q.push window
              start_sub.subscription = scheduler.schedule_relative(time_shift, start_window)
              observer.on_next window
            end
          end
        end

        start_window.call

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            windows = gate.synchronize { q.dup }
            windows.each { |s| s.on_next x }
          end

          o.on_error do |err|
            gate.synchronize do
              stopped = true
              q.each { |s| s.on_error err }
              observer.on_error err
            end
          end

          o.on_completed do
            gate.synchronize do
              stopped = true
              q.each { |s| s.on_completed }
              observer.on_completed
            end
          end
        end

        subscription = subscribe(new_obs)

        CompositeSubscription.new [start_sub, close_subs, subscription]
      end
    end
  end
end
