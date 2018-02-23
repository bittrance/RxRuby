module Rx
  class ConnectableObservable < AnonymousObservable
    def initialize(source, subject)
      @has_subscription = false
      @subscription = nil
      @source_observable = source.as_observable
      @subject = subject

      super(&subject.method(:subscribe))
    end

    def connect
      unless @has_subscription
        @has_subscription = true
        @subscription = CompositeSubscription.new [@source_observable.subscribe(@subject), Subscription.create { @has_subscription = false }]
      end
      @subscription
    end

    def ref_count
      count = 0
      gate = Mutex.new
      connectable_subscription = nil
      AnonymousObservable.new do |observer|
        gate.synchronize do
          count += 1
          connectable_subscription ||= connect
        end
        new_obs = subscribe(observer)
        counting_sub = Subscription.create do
          gate.synchronize do
            if (count -= 1) == 0
              connectable_subscription.unsubscribe
            end
          end
        end

        CompositeSubscription.new [new_obs, counting_sub]
      end
    end
  end
end
