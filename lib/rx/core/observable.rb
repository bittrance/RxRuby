# Copyright (c) Microsoft Open Technologies, Inc. All rights reserved. See License.txt in the project root for license information.

require 'rx/concurrency/current_thread_scheduler'
require 'rx/concurrency/immediate_scheduler'
require 'rx/core/observer'
require 'rx/core/auto_detach_observer'
require 'rx/subscriptions/subscription'

module Rx

  module Observable
    # Subscribes the given observer to the observable sequence.
    # @param [Observer] observer
    # @return [Subscription]
    def subscribe(*args)
      observer = normalize_observer(*args)
      _subscribe AutoDetachObserver.new observer
    end

    # Subscribe to this observable sequence and block until this sequence completes
    # or errors.
    # @param [Number] timeout Wait no more than this number of seconds
    # @param [args...] One of the alternative observer configurations listed above
    # @return [Boolean] True if the observable completed or errored, or false if timeout was reached.
    def subscribe_blocking(timeout, *args)
      observer = normalize_observer(*args)
      blocking = BlockingObserver.new observer
      _subscribe blocking
      blocking.await(timeout)
    end

    # Subscribes the given block to the on_next action of the observable sequence.
    # @param [Object] block
    # @return [Subscription]
    def subscribe_on_next(&block)
      raise ArgumentError.new 'Block is required' unless block_given?
      subscribe(Observer.configure {|o| o.on_next(&block) })
    end

    # Subscribes the given block to the on_error action of the observable sequence.
    def subscribe_on_error(&block)
      raise ArgumentError.new 'Block is required' unless block_given?
      subscribe(Observer.configure {|o| o.on_error(&block) })
    end

    # Subscribes the given block to the on_completed action of the observable sequence.
    def subscribe_on_completed(&block)
      raise ArgumentError.new 'Block is required' unless block_given?
      subscribe(Observer.configure {|o| o.on_completed(&block) })
    end

    private

    def normalize_observer(*args)
      case args.size
      when 0
        if block_given?
          Observer.configure {|o| o.on_next(&Proc.new) }
        else
          Observer.configure
        end
      when 1
        raise ArgumentError.new 'Must pass observer as single argument' unless args[0].is_a? ObserverBase
        args[0]
      when 3
        Observer.configure {|o|
          o.on_next(&args[0])
          o.on_error(&args[1])
          o.on_completed(&args[2])
        }
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 0..1 or 3)"
      end
    end

    def _subscribe(observer)
      if CurrentThreadScheduler.schedule_required?
        CurrentThreadScheduler.instance.schedule_with_state observer, method(:schedule_subscribe)
      else
        schedule_subscribe(nil, observer)
      end
      observer
    end

    def schedule_subscribe(_, auto_detach_observer)
      begin
        auto_detach_observer.subscription = subscribe_core auto_detach_observer
      rescue => e
        raise e unless auto_detach_observer.fail e
      end

      Subscription.empty
    end
  end

  class AnonymousObservable

    include Observable

    def initialize(&subscribe)
      @subscribe = subscribe
    end

    protected

    def subscribe_core(obs)
      @subscribe.call(obs) || Subscription.empty
    end

  end

end
