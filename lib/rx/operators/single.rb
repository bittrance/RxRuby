# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/subscriptions/subscription'
require 'rx/subscriptions/composite_subscription'
require 'rx/subscriptions/ref_count_subscription'
require 'rx/subscriptions/single_assignment_subscription'
require 'rx/core/observer'
require 'rx/core/observable'
require 'rx/operators/creation'

module Rx

  module Observable

    # Hides the identity of an observable sequence.
    def as_observable
      AnonymousObservable.new {|observer| subscribe(observer) }
    end

    # Projects each element of an observable sequence into zero or more buffers which are produced based on element count information.
    def buffer_with_count(count, skip = count)
      raise ArgumentError.new 'Count must be greater than zero' if count <= 0
      raise ArgumentError.new 'Skip must be greater than zero' if skip <= 0
      window_with_count(count, skip).flat_map(&:to_a).find_all {|x| x.length > 0 }
    end

    # Dematerializes the explicit notification values of an observable sequence as implicit notifications.
    def dematerialize
      AnonymousObservable.new do |observer|

        new_obs = Rx::Observer.configure do |o|
          o.on_next {|x| x.accept observer }
          o.on_error(&observer.method(:on_error))
          o.on_completed(&observer.method(:on_completed))
        end

        subscribe new_obs
      end
    end

    # Returns an observable sequence that contains only distinct contiguous elements according to the optional key_selector.
    def distinct_until_changed(&comparator)
      comparator ||= lambda {|l, r| l == r }
      AnonymousObservable.new do |observer|
        current_value = nil
        has_current = false

        new_obs = Rx::Observer.configure do |o|
          o.on_next do |value|
            begin
              if !has_current || !comparator.call(current_value, value)
                has_current = true
                current_value = value
                observer.on_next value
              end
            rescue => err
              observer.on_error err
            end
          end

          o.on_error(&observer.method(:on_error))
          o.on_completed(&observer.method(:on_completed))
        end

        subscribe new_obs
      end
    end

    # Invokes a specified action after the source observable sequence terminates gracefully or exceptionally.
    def ensures
      AnonymousObservable.new do |observer|
        subscription = subscribe observer
        Subscription.create do
          begin
            subscription.unsubscribe
          ensure
            yield
          end
        end
      end
    end

    # Ignores all elements in an observable sequence leaving only the termination messages.
    def ignore_elements
      AnonymousObservable.new do |observer|
        new_obs = Rx::Observer.configure do |o|
          o.on_next {|_| }
          o.on_error(&observer.method(:on_error))
          o.on_completed(&observer.method(:on_completed))
        end

        subscribe new_obs
      end
    end

    # Materializes the implicit notifications of an observable sequence as explicit notification values.
    def materialize
      AnonymousObservable.new do |observer|
        new_obs = Rx::Observer.configure do |o|

          o.on_next {|x| observer.on_next(Notification.create_on_next x) }

          o.on_error do |err|
            observer.on_next(Notification.create_on_error err)
            observer.on_completed
          end

          o.on_completed do
            observer.on_next(Notification.create_on_completed)
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Repeats the observable sequence indefinitely.
    def repeat_infinitely
      Observable.concat(enumerator_repeat_infinitely(self))
    end

    # Repeats the observable sequence a specified number of times.
    def repeat(repeat_count)
      Observable.concat(enumerator_repeat_times(repeat_count, self))
    end

    # Repeats the source observable sequence until it successfully terminates.
    def retry_infinitely
      Observable.rescue_error(enumerator_repeat_infinitely(self))
    end

    # Repeats the source observable sequence the specified number of times or until it successfully terminates.
    def retry(retry_count)
      Observable.rescue_error(enumerator_repeat_times(retry_count, self))
    end

    # Applies an accumulator function over an observable sequence and returns each intermediate result.
    # The optional seed value is used as the initial accumulator value.
    # For aggregation behavior with no intermediate results, see Observable.reduce.
    def scan(*args, &block)
      has_seed = false
      seed = nil
      action = nil

      # Argument parsing to support:
      # 1. (seed, Symbol)
      # 2. (seed, &block)
      # 3. (Symbol)
      # 4. (&block)
      if args.length == 2 && args[1].is_a?(Symbol)
        seed = args[0]
        action = args[1].to_proc
        has_seed = true
      elsif args.length == 1 && block_given?
        seed = args[0]
        has_seed = true
        action = block
      elsif args.length == 1 && args[0].is_a?(Symbol)
        action = args[0].to_proc
      elsif args.length == 0 && block_given?
        action = block
      else
        raise ArgumentError.new 'Invalid arguments'
      end

      AnonymousObservable.new do |observer|

        has_accumulation = false
        accumulation = nil
        has_value = false

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            begin
              has_value = true unless has_value

              if has_accumulation
                accumulation = action.call(accumulation, x)
              else
                accumulation = has_seed ? action.call(seed, x) : x
                has_accumulation = true
              end
            rescue => err
              observer.on_error err
              next
            end

            observer.on_next accumulation
          end

          o.on_error(&observer.method(:on_error))

          o.on_completed do
            observer.on_next seed if !has_value && has_seed
            observer.on_completed
          end
        end

        subscribe new_obs
      end
    end

    # Bypasses a specified number of elements at the end of an observable sequence.
    # @param [Numeric] count The number of elements to bypass at the end of an observable sequence.
    def skip_last(count)
      raise ArgumentError.new 'Count cannot be less than zero' if count < 0
      AnonymousObservable.new do |observer|
        q = []
        new_obs = Observer.configure do |o|

          o.on_next do |x|
            q.push x
            observer.on_next(q.shift) if q.length > count
          end

          o.on_error(&observer.method(:on_error))
          o.on_completed(&observer.method(:on_completed))
        end

        subscribe new_obs
      end
    end

    # Prepends a sequence of values to an observable sequence.
    def start_with(*args)
      scheduler = CurrentThreadScheduler.instance
      if args.size > 0 && Scheduler === args[0]
        scheduler = args.shift
      end
      Observable.from_array(args, scheduler).concat(self)
    end

    # Returns a specified number of contiguous elements from the end of an observable sequence.
    def take_last(count, scheduler = CurrentThreadScheduler.instance)
      raise ArgumentError.new 'Count cannot be less than zero' if count < 0
      AnonymousObservable.new do |observer|
        q = []
        g = CompositeSubscription.new

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            q.push x
            q.shift if q.length > count
          end

          o.on_error(&observer.method(:on_error))

          o.on_completed do
            g.push(scheduler.schedule_recursive lambda {|this|
              if q.length > 0
                observer.on_next(q.shift)
                this.call
              else
                observer.on_completed
              end
            })
          end
        end

        g << subscribe(new_obs)
      end
    end

    # Projects each element of an observable sequence into zero or more windows which are produced based on element count information.
    def window_with_count(count, skip)
      raise ArgumentError.new 'Count must be greater than zero' if count <= 0
      raise ArgumentError.new 'Skip must be greater than zero' if skip <= 0

      AnonymousObservable.new do |observer|
        q = []
        n = 0

        m = SingleAssignmentSubscription.new
        ref_count_disposable = RefCountSubscription.new m

        create_window = lambda {
          s = Subject.new
          q.push s
          observer.on_next(s.add_ref(ref_count_disposable))
        }

        create_window.call

        new_obs = Observer.configure do |o|
          o.on_next do |x|
            q.each {|s| s.on_next x}

            c = n - count + 1
            q.shift.on_completed if c >=0 && c % skip == 0

            n += 1
            create_window.call if n % skip == 0
          end

          o.on_error do |err|
            q.shift.on_error err while q.length > 0
            observer.on_error err
          end

          o.on_completed do
            q.shift.on_completed while q.length > 0
            observer.on_completed
          end
        end

        m.subscription = subscribe new_obs
        ref_count_disposable
      end
    end

    def enumerator_repeat_times(num, value)
      raise ArgumentError.new("Expected #{num} to be an integer") unless num.is_a? Integer
      ThreadedEnumerator.new do |y|
        num.times do |i|
          y << value
        end
      end
    end

    def enumerator_repeat_infinitely(value)
      ThreadedEnumerator.new do |y|
        while true
          y << value
        end
      end
    end

  end
end
