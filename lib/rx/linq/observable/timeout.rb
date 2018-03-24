module Rx
  class TimeoutError < RuntimeError ; end

  module Observable
    def timeout(deadline, scheduler = CurrentThreadScheduler.instance)
      AnonymousObservable.new do |observer|
        gate = Mutex.new
        serial = SerialSubscription.new
      
        setup_timeout = lambda do
          c = scheduler.schedule_relative(deadline, lambda do
            err = TimeoutError.new
            gate.synchronize { observer.on_error(err) }
          end)
          serial.subscription = c
          c
        end

        cancelable = setup_timeout.call
        new_obs = Observer.configure do |o|
          o.on_next do |v|
            cancelable.unsubscribe
            gate.synchronize do
              unless observer.stopped?
                cancelable = setup_timeout.call
                observer.on_next(v)
              end
            end
          end
          o.on_error do |err|
            cancelable.unsubscribe
            gate.synchronize { observer.on_error(err) }
          end
          o.on_completed do
            cancelable.unsubscribe
            gate.synchronize { observer.on_completed }
          end
        end

        CompositeSubscription.new [subscribe(new_obs), serial]
      end
    end
  end
end
