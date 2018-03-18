module Rx
  module Observable
    def delay_with_selector(subscription_delay = nil, &block)
      raise ArgumentError, 'Must provide a block' unless block_given?

      AnonymousObservable.new do |observer|
        delays = CompositeSubscription.new
        at_end = false
        done = lambda {
          if at_end && delays.length == 0
            observer.on_completed
          end
        }
        subscription = SerialSubscription.new
        start = lambda {|*_|
          subscription.subscription = subscribe(
            lambda {|x|
              begin
                delay = yield x
              rescue => error
                observer.on_error error
                return
              end
              d = SingleAssignmentSubscription.new
              delays.push(d)
              d.subscription = delay.subscribe(
                lambda {|_|
                  observer.on_next x
                  delays.delete(d)
                  done.call
                },
                observer.method(:on_error),
                lambda {
                  observer.on_next x
                  delays.delete(d)
                  done.call
                })
            },
            observer.method(:on_error),
            lambda {
              at_end = true
              subscription.unsubscribe
              done.call
            })
        }

        if subscription_delay
          subscription.subscription = subscription_delay.subscribe(
            start,
            observer.method(:on_error),
            start)
        else
          start.call
        end
        CompositeSubscription.new [subscription, delays]
      end
    end
  end
end
